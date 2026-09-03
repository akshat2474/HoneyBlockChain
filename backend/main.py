import json
import logging
import math
import time
from fastapi import FastAPI, WebSocket, WebSocketDisconnect

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="IDR Backend - Dead Reckoning")

# Earth radius in meters
EARTH_RADIUS = 6378137.0

def calculate_new_position(lat, lon, distance, heading_rad):
    """
    Calculates the new lat/lon given a distance in meters and heading in radians.
    Assuming North is 0 radians, East is pi/2. 
    However, our gyro Z axis integrates relative rotation.
    We will just treat heading_rad=0 as North for simplicity of the prototype.
    """
    # Convert lat/lon to radians
    lat_rad = math.radians(lat)
    
    # Coordinate offsets in radians
    d_lat = (distance * math.cos(heading_rad)) / EARTH_RADIUS
    d_lon = (distance * math.sin(heading_rad)) / (EARTH_RADIUS * math.cos(lat_rad))
    
    # New coordinates
    new_lat = lat + math.degrees(d_lat)
    new_lon = lon + math.degrees(d_lon)
    return new_lat, new_lon


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    logger.info(f"Client connected: {websocket.client}")
    
    # State variables for Dead Reckoning
    current_lat = None
    current_lon = None
    heading_rad = 0.0
    last_timestamp = None
    
    try:
        while True:
            data = await websocket.receive_text()
            
            try:
                payload = json.loads(data)
                
                gnss_active = payload.get("gnss_active", True)
                timestamp = payload.get("timestamp", time.time() * 1000)
                
                # dt in seconds
                dt = (timestamp - last_timestamp) / 1000.0 if last_timestamp else 0.2
                last_timestamp = timestamp
                
                if gnss_active:
                    # Sync our state with the ground truth GNSS
                    loc = payload.get("location")
                    if loc:
                        current_lat = loc.get("lat")
                        current_lon = loc.get("lon")
                        
                    # Reset heading assumption to North (0) for prototype simplicity
                    heading_rad = 0.0 
                    
                    response = {
                        "mode": "GNSS_ACTIVE",
                        "status": "Tracking real GPS"
                    }
                    await websocket.send_text(json.dumps(response))
                    
                else:
                    # GNSS is simulated to be lost. Perform Dead Reckoning.
                    if current_lat is None or current_lon is None:
                        # Cannot DR without a starting point
                        await websocket.send_text(json.dumps({"error": "No initial GPS fix to start DR"}))
                        continue
                        
                    accel = payload.get("accel", [0, 0, 0])
                    gyro = payload.get("gyro", [0, 0, 0])
                    
                    # 1. Update Heading (Integrate Gyroscope Z-axis)
                    # Gyro Z is rotation around vertical axis (if phone is held flat)
                    # Note: Depending on device, positive Z might be CCW. We subtract to turn it into standard compass heading change.
                    gyro_z = gyro[2] if gyro else 0.0
                    
                    # Ignore tiny gyro noise
                    if abs(gyro_z) < 0.05:
                        gyro_z = 0.0
                        
                    heading_rad -= gyro_z * dt 
                    
                    # 2. Estimate Speed (Walking heuristic)
                    # Simple heuristic: if overall acceleration magnitude varies significantly from gravity (9.8), user is stepping.
                    accel_mag = math.sqrt(accel[0]**2 + accel[1]**2 + accel[2]**2) if accel else 9.81
                    accel_variance = abs(accel_mag - 9.81)
                    
                    # Lower threshold to 0.2 so even gentle walking triggers it.
                    # Increase speed to 2.0 m/s so it moves noticeably on the map.
                    speed = 2.0 if accel_variance > 0.2 else 0.0
                    
                    distance_moved = speed * dt
                    
                    # 3. Update Position
                    current_lat, current_lon = calculate_new_position(
                        current_lat, current_lon, distance_moved, heading_rad
                    )
                    
                    response = {
                        "mode": "DEAD_RECKONING",
                        "estimated_location": {
                            "lat": current_lat,
                            "lon": current_lon
                        },
                        "debug": {
                            "speed": speed,
                            "heading_deg": math.degrees(heading_rad) % 360,
                            "accel_var": accel_variance
                        }
                    }
                    
                    await websocket.send_text(json.dumps(response))
                    
            except json.JSONDecodeError:
                logger.error("Failed to parse JSON")
                await websocket.send_text(json.dumps({"error": "Invalid JSON"}))
                
    except WebSocketDisconnect:
        logger.info("Client disconnected")
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
