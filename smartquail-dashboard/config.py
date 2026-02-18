"""
SmartQuail Configuration
========================
Konfigurasi untuk SmartQuail IoT Dashboard
"""

import os

# =============================================================================
# SUPABASE CONFIGURATION
# =============================================================================
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://gveihacupcvnzycpeqmo.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd2ZWloYWN1cGN2bnp5Y3BlcW1vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzNzY2MDgsImV4cCI6MjA4Njk1MjYwOH0.HAGi45u7frXdgYV4IP2FMFP-kjCw39haeJgDctJFnHQ")

# =============================================================================
# MQTT CONFIGURATION
# =============================================================================
MQTT_BROKER = "broker.hivemq.com"
MQTT_PORT = 1883
MQTT_TOPIC = "iot/smartquail/dht"
MQTT_CLIENT_ID = "streamlit-smartquail-dashboard"

# =============================================================================
# THI THRESHOLDS (Temperature Humidity Index)
# =============================================================================
THI_NORMAL = 72      # < 72 = Normal (hijau)
THI_WARNING = 78     # 72-78 = Warning (kuning)
THI_DANGER = 85      # > 78 = Danger (merah), > 85 = Critical

# =============================================================================
# OPTIMAL RANGES FOR QUAIL
# =============================================================================
TEMP_MIN_OPTIMAL = 23  # °C
TEMP_MAX_OPTIMAL = 26  # °C
HUMIDITY_MIN_OPTIMAL = 60  # %
HUMIDITY_MAX_OPTIMAL = 70  # %

# =============================================================================
# DASHBOARD SETTINGS
# =============================================================================
REFRESH_INTERVAL = 2  # seconds
HISTORY_HOURS = 24    # hours of history to display
MAX_DATA_POINTS = 1000  # maximum data points to load

# =============================================================================
# TRANSLATIONS (Bilingual ID/EN)
# =============================================================================
TRANSLATIONS = {
    "en": {
        "title": "SmartQuail Dashboard",
        "subtitle": "Intelligent Aviary Monitoring",
        "temperature": "Temperature",
        "humidity": "Humidity",
        "thi": "THI Index",
        "relay": "Cooling System",
        "status": "Status",
        "normal": "Normal",
        "warning": "Warning",
        "danger": "Danger",
        "critical": "Critical",
        "on": "Active",
        "off": "Standby",
        "last_update": "Last Update",
        "history": "History",
        "statistics": "Statistics",
        "download": "Download Data",
        "settings": "Settings",
        "language": "Language",
        "device": "Device",
        "avg": "Average",
        "min": "Minimum",
        "max": "Maximum",
        "current": "Current",
        "trend": "Trend",
        "hours": "hours",
        "optimal_range": "Optimal Range",
        "quail_comfort": "Quail Comfort Zone",
        "system_status": "System Status",
        "connected": "Connected",
        "disconnected": "Disconnected",
        "sensor_error": "Sensor Error",
        "all_systems_normal": "All systems operating normally",
        "cooling_active": "Cooling system is active",
        "check_environment": "Check environment conditions",
        "no_data": "No data available",
        "loading": "Loading...",
    },
    "id": {
        "title": "SmartQuail Dashboard",
        "subtitle": "Monitoring Kandang Cerdas",
        "temperature": "Suhu",
        "humidity": "Kelembaban",
        "thi": "Indeks THI",
        "relay": "Sistem Pendingin",
        "status": "Status",
        "normal": "Normal",
        "warning": "Perhatian",
        "danger": "Bahaya",
        "critical": "Kritis",
        "on": "Aktif",
        "off": "Standby",
        "last_update": "Update Terakhir",
        "history": "Riwayat",
        "statistics": "Statistik",
        "download": "Unduh Data",
        "settings": "Pengaturan",
        "language": "Bahasa",
        "device": "Perangkat",
        "avg": "Rata-rata",
        "min": "Minimum",
        "max": "Maksimum",
        "current": "Saat Ini",
        "trend": "Tren",
        "hours": "jam",
        "optimal_range": "Rentang Optimal",
        "quail_comfort": "Zona Nyaman Puyuh",
        "system_status": "Status Sistem",
        "connected": "Terhubung",
        "disconnected": "Terputus",
        "sensor_error": "Error Sensor",
        "all_systems_normal": "Semua sistem berjalan normal",
        "cooling_active": "Sistem pendingin aktif",
        "check_environment": "Periksa kondisi lingkungan",
        "no_data": "Tidak ada data",
        "loading": "Memuat...",
    }
}

def get_text(key: str, lang: str = "en") -> str:
    """Get translated text"""
    return TRANSLATIONS.get(lang, TRANSLATIONS["en"]).get(key, key)
