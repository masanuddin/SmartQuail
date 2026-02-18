"""
SmartQuail - MQTT subscriber. Receives messages from broker.hivemq.com
topic: iot/smartquail/dht and saves to Supabase.
Run in background thread from Streamlit.
"""

import json
import threading
from typing import Callable, Optional

try:
    import paho.mqtt.client as mqtt
except ImportError:
    mqtt = None

from config import MQTT_BROKER, MQTT_PORT, MQTT_TOPIC, MQTT_KEEPALIVE
from supabase_client import insert_reading


def _on_connect(client, userdata, flags, rc):
    if rc == 0:
        client.subscribe(MQTT_TOPIC)


def _on_message(client, userdata, msg):
    try:
        payload = json.loads(msg.payload.decode())
        device = payload.get("device", "esp32-01")
        temp = float(payload.get("temp", 0))
        rh = float(payload.get("rh", 0))
        thi = float(payload.get("thi", 0))
        relay = str(payload.get("relay", "OFF")).upper()
        status = str(payload.get("status", "OK"))
        insert_reading(device, temp, rh, thi, relay, status)
    except Exception:
        pass


def start_mqtt_thread():
    """Start MQTT subscriber in a daemon thread. Idempotent."""
    if not mqtt:
        return
    if getattr(start_mqtt_thread, "_started", False):
        return
    client = mqtt.Client()
    client.on_connect = _on_connect
    client.on_message = _on_message
    try:
        client.connect(MQTT_BROKER, MQTT_PORT, MQTT_KEEPALIVE)
        client.loop_start()
        start_mqtt_thread._started = True
    except Exception:
        pass
