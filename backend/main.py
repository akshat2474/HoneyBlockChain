import json
import logging
import math
import time
from collections import deque
from fastapi import FastAPI, WebSocket, WebSocketDisconnect

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="IDR Backend - Dead Reckoning")

EARTH_RADIUS = 6378137.0

# Complementary filter weight.
# 0.96 = trust gyro 96% (smooth, short-term accurate),
# trust magnetometer 4% (drifts slowly back to true North, prevents long-term drift).
COMPLEMENTARY_ALPHA = 0.96

def calculate_new_position(lat, lon, distance, heading_rad):
    """
    Calculates new lat/lon given distance in meters and heading in radians.
    North = 0, East = pi/2.
    """
    lat_rad = math.radians(lat)
    d_lat = (distance * math.cos(heading_rad)) / EARTH_RADIUS
    d_lon = (distance * math.sin(heading_rad)) / (EARTH_RADIUS * math.cos(lat_rad))
    return lat + math.degrees(d_lat), lon + math.degrees(d_lon)


def angle_lerp(a, b, t):
    """
    Linearly interpolate between two angles (in radians), correctly
    handling the 0/2pi wraparound so we don't spin 350 degrees
    the wrong way.
    """
    diff = (b - a + math.pi) % (2 * math.pi) - math.pi
    return a + t * diff


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    logger.info(f"Client connected: {websocket.client}")

    # --- Dead Reckoning State ---
    current_lat = None
    current_lon = None
    heading_rad = 0.0         # Current fused heading
    last_timestamp = None

    # Rolling window for accel variance (smoother step detection)
    accel_window = deque(maxlen=5)  # last 5 samples (~1 second at 5Hz)

    try:
        while True:
            data = await websocket.receive_text()

            try:
                payload = json.loads(data)

                gnss_active = payload.get("gnss_active", True)
                timestamp = payload.get("timestamp", time.time() * 1000)

                # Clamp dt to avoid huge jumps on reconnect
                if last_timestamp:
                    dt = min((timestamp - last_timestamp) / 1000.0, 0.5)
                else:
                    dt = 0.2
                last_timestamp = timestamp

                mag = payload.get("mag")
                mag_heading = None
                if mag and len(mag) == 3:
                    # Standard compass heading from magnetometer (radians)
                    mag_heading = math.atan2(-mag[0], mag[1])

                if gnss_active:
                    # Sync position with ground truth GPS
                    loc = payload.get("location")
                    if loc:
                        current_lat = loc.get("lat")
                        current_lon = loc.get("lon")

                    # While GNSS is active, keep heading fused so it's ready
                    # the moment blackout is triggered
                    if mag_heading is not None:
                        heading_rad = mag_heading

                    await websocket.send_text(json.dumps({
                        "mode": "GNSS_ACTIVE",
                        "status": "Tracking real GPS"
                    }))

                else:
                    # --- GNSS BLACKOUT: Dead Reckoning ---
                    if current_lat is None or current_lon is None:
                        await websocket.send_text(json.dumps({"error": "No initial GPS fix"}))
                        continue

                    accel = payload.get("accel") or [0, 0, 9.81]
                    gyro  = payload.get("gyro")  or [0, 0, 0]

                    # ── 1. HEADING via Complementary Filter ──────────────────
                    # Gyroscope prediction (fast, short-term accurate)
                    gyro_z = gyro[2]
                    if abs(gyro_z) < 0.05:   # deadband: kill sensor noise floor
                        gyro_z = 0.0
                    gyro_heading = heading_rad - gyro_z * dt

                    # Fuse with magnetometer (slow, long-term stable)
                    if mag_heading is not None:
                        heading_rad = angle_lerp(gyro_heading, mag_heading, 1.0 - COMPLEMENTARY_ALPHA)
                    else:
                        heading_rad = gyro_heading

                    # ── 2. SPEED via rolling-window step detection ───────────
                    accel_mag = math.sqrt(accel[0]**2 + accel[1]**2 + accel[2]**2)
                    accel_variance = abs(accel_mag - 9.81)
                    accel_window.append(accel_variance)

                    # Use mean variance over the window to smooth out spike noise
                    mean_variance = sum(accel_window) / len(accel_window)
                    speed = 1.3 if mean_variance > 0.2 else 0.0

                    # ── 3. POSITION UPDATE ───────────────────────────────────
                    distance_moved = speed * dt
                    current_lat, current_lon = calculate_new_position(
                        current_lat, current_lon, distance_moved, heading_rad
                    )

                    await websocket.send_text(json.dumps({
                        "mode": "DEAD_RECKONING",
                        "estimated_location": {
                            "lat": current_lat,
                            "lon": current_lon
                        },
                        "debug": {
                            "speed": speed,
                            "heading_deg": math.degrees(heading_rad) % 360,
                            "accel_var": round(mean_variance, 3)
                        }
                    }))

            except json.JSONDecodeError:
                logger.error("Failed to parse JSON")
                await websocket.send_text(json.dumps({"error": "Invalid JSON"}))

    except WebSocketDisconnect:
        logger.info("Client disconnected")
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
