"""
SmartQuail MQTT to Supabase Bridge
==================================
Subscribes to MQTT broker and stores data in Supabase

Run this script separately from the Streamlit dashboard.
It will run continuously and push data to Supabase.

Usage:
    python mqtt_bridge.py
"""

import paho.mqtt.client as mqtt
import json
import time
from datetime import datetime
import config
import database as db

# =============================================================================
# MQTT CALLBACKS
# =============================================================================
def on_connect(client, userdata, flags, rc):
    """Callback when connected to MQTT broker"""
    if rc == 0:
        print(f"[✅] Connected to MQTT Broker: {config.MQTT_BROKER}")
        print(f"[📡] Subscribing to topic: {config.MQTT_TOPIC}")
        client.subscribe(config.MQTT_TOPIC)
    else:
        print(f"[❌] Connection failed with code: {rc}")
        error_codes = {
            1: "Incorrect protocol version",
            2: "Invalid client identifier",
            3: "Server unavailable",
            4: "Bad username or password",
            5: "Not authorized"
        }
        print(f"    Error: {error_codes.get(rc, 'Unknown error')}")

def on_disconnect(client, userdata, rc):
    """Callback when disconnected from MQTT broker"""
    print(f"[⚠️] Disconnected from MQTT Broker (code: {rc})")
    if rc != 0:
        print("[🔄] Attempting to reconnect...")

def on_message(client, userdata, msg):
    """Callback when message received"""
    try:
        # Parse JSON payload
        payload = json.loads(msg.payload.decode())
        
        # Print received data
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"\n[📨] {timestamp} - New Data Received:")
        print(f"    Device: {payload.get('device', 'unknown')}")
        print(f"    Temp: {payload.get('temp', 0)}°C")
        print(f"    RH: {payload.get('rh', 0)}%")
        print(f"    THI: {payload.get('thi', 0)}")
        print(f"    Relay: {payload.get('relay', 'OFF')}")
        print(f"    Status: {payload.get('status', 'OK')}")
        
        # Insert into Supabase
        success = db.insert_sensor_data(payload)
        
        if success:
            print(f"    [✅] Saved to Supabase")
        else:
            print(f"    [❌] Failed to save to Supabase")
            
    except json.JSONDecodeError as e:
        print(f"[❌] JSON Parse Error: {e}")
        print(f"    Raw payload: {msg.payload}")
    except Exception as e:
        print(f"[❌] Error processing message: {e}")

def on_subscribe(client, userdata, mid, granted_qos):
    """Callback when subscribed to topic"""
    print(f"[✅] Subscribed successfully (QoS: {granted_qos[0]})")

# =============================================================================
# MAIN
# =============================================================================
def main():
    print("=" * 60)
    print("🐦 SmartQuail MQTT to Supabase Bridge")
    print("=" * 60)
    print(f"Broker: {config.MQTT_BROKER}:{config.MQTT_PORT}")
    print(f"Topic: {config.MQTT_TOPIC}")
    print(f"Supabase URL: {config.SUPABASE_URL[:50]}...")
    print("=" * 60)
    print()
    
    # Create MQTT client
    client = mqtt.Client(client_id=config.MQTT_CLIENT_ID)
    
    # Set callbacks
    client.on_connect = on_connect
    client.on_disconnect = on_disconnect
    client.on_message = on_message
    client.on_subscribe = on_subscribe
    
    # Connect to broker
    try:
        print(f"[🔌] Connecting to {config.MQTT_BROKER}...")
        client.connect(config.MQTT_BROKER, config.MQTT_PORT, 60)
    except Exception as e:
        print(f"[❌] Failed to connect: {e}")
        return
    
    # Start loop
    print("[🚀] Starting MQTT loop... Press Ctrl+C to stop.\n")
    
    try:
        client.loop_forever()
    except KeyboardInterrupt:
        print("\n[👋] Shutting down...")
        client.disconnect()
        print("[✅] Disconnected. Goodbye!")

if __name__ == "__main__":
    main()
