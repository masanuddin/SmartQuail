# SmartQuail Dashboard - Configuration
# Set SUPABASE_URL and SUPABASE_KEY in Streamlit Cloud Secrets or .env

import os
from dotenv import load_dotenv

load_dotenv()

# Supabase (required for history & real-time)
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "")

# MQTT
MQTT_BROKER = os.getenv("MQTT_BROKER", "broker.hivemq.com")
MQTT_PORT = int(os.getenv("MQTT_PORT", "1883"))
MQTT_TOPIC = os.getenv("MQTT_TOPIC", "iot/smartquail/dht")
MQTT_KEEPALIVE = 60

# App
REFRESH_INTERVAL_SEC = 2
HISTORY_HOURS = 24
THI_NORMAL_MAX = 72
THI_WARNING_MAX = 78
# THI > 78 = DANGER
