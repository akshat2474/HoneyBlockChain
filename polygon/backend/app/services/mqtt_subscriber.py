"""MQTT subscriber — runs as a background thread and inserts sensor readings into the DB.

Start it once on app startup. It connects to the Mosquitto broker and subscribes to
the topic `honeychain/hives/+/telemetry`. Each received JSON payload is parsed and
written to the `sensor_readings` table.

Expected JSON payload (from ESP32 or simulator):
{
  "hiveId": "UUID-string",
  "deviceId": "ESP32-001",
  "temperatureC": 34.2,
  "humidityPct": 61.8,
  "pressureHPa": 1009.4,
  "weightKg": 27.35,
  "batteryPct": 84,
  "timestamp": "2026-09-05T10:30:00+05:30",
  "isSimulated": false
}
"""
from __future__ import annotations

import json
import logging
import os
import uuid
from datetime import datetime, timezone
from threading import Thread
from typing import Any, Dict

import paho.mqtt.client as mqtt
from dotenv import load_dotenv

load_dotenv()

log = logging.getLogger("honeychain.mqtt")

MQTT_HOST = os.getenv("MQTT_HOST", "localhost")
MQTT_PORT = int(os.getenv("MQTT_PORT", "1883"))
TOPIC = "honeychain/hives/+/telemetry"


def _parse_payload(raw: bytes) -> Dict[str, Any]:
    return json.loads(raw.decode())


def _hive_id_from_payload(data: Dict[str, Any]) -> uuid.UUID:
    return uuid.UUID(data["hiveId"])


def _ts_from_payload(data: Dict[str, Any]) -> datetime:
    ts_str = data.get("timestamp")
    if ts_str:
        return datetime.fromisoformat(ts_str)
    return datetime.now(timezone.utc)


def _insert_reading(data: Dict[str, Any]) -> None:
    """Write one sensor reading to the database in its own short-lived session."""
    # Import here to avoid circular imports at module load time.
    from app.database import SessionLocal
    from app.models.hive import SensorReading

    hive_id = _hive_id_from_payload(data)
    ts = _ts_from_payload(data)

    reading = SensorReading(
        hive_id=hive_id,
        ts=ts,
        temperature_c=data.get("temperatureC"),
        humidity_pct=data.get("humidityPct"),
        pressure_hpa=data.get("pressureHPa"),
        weight_kg=data.get("weightKg"),
        battery_pct=data.get("batteryPct"),
        source="mqtt",
        is_simulated=data.get("isSimulated", False),
    )
    db = SessionLocal()
    try:
        db.add(reading)
        db.commit()
        log.info("MQTT: saved reading for hive %s", hive_id)
    except Exception as exc:
        db.rollback()
        log.error("MQTT: DB insert failed — %s", exc)
    finally:
        db.close()


def _on_message(_client, _userdata, message: mqtt.MQTTMessage) -> None:
    try:
        data = _parse_payload(message.payload)
        _insert_reading(data)
    except Exception as exc:
        log.warning("MQTT: could not process message — %s", exc)


def _on_connect(client, _userdata, _flags, rc: int, _properties=None) -> None:
    if rc == 0:
        client.subscribe(TOPIC)
        log.info("MQTT: connected and subscribed to %s", TOPIC)
    else:
        log.error("MQTT: connection refused, rc=%d", rc)


def start_mqtt_subscriber() -> None:
    """Start the MQTT subscriber in a daemon thread. Safe to call multiple times."""
    client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
    client.on_connect = _on_connect
    client.on_message = _on_message

    def _run():
        try:
            client.connect(MQTT_HOST, MQTT_PORT, keepalive=60)
            client.loop_forever()
        except Exception as exc:
            log.warning("MQTT: could not connect to broker — %s. Telemetry disabled.", exc)

    thread = Thread(target=_run, daemon=True, name="mqtt-subscriber")
    thread.start()
    log.info("MQTT subscriber thread started (broker=%s:%d)", MQTT_HOST, MQTT_PORT)
