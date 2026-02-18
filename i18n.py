# Bilingual strings for SmartQuail Dashboard (ID / EN)

TEXTS = {
    "title": {"id": "SmartQuail Monitoring", "en": "SmartQuail Monitoring"},
    "subtitle": {"id": "Dashboard Kandang Puyuh", "en": "Quail House Dashboard"},
    "temp": {"id": "Suhu", "en": "Temperature"},
    "humidity": {"id": "Kelembapan", "en": "Humidity"},
    "thi": {"id": "THI", "en": "THI"},
    "relay": {"id": "Relay", "en": "Relay"},
    "status_ok": {"id": "Kondisi normal", "en": "Normal"},
    "status_warning": {"id": "THI mendekati batas", "en": "THI approaching limit"},
    "status_danger": {"id": "THI bahaya - butuh tindakan", "en": "THI danger - action needed"},
    "trend_title": {"id": "Suhu & Kelembapan (1 jam terakhir)", "en": "Temperature & Humidity (Last 1 Hour)"},
    "gauge_title": {"id": "Indikator THI", "en": "THI Gauge"},
    "zone_normal": {"id": "Aman", "en": "Normal"},
    "zone_warning": {"id": "Waspada", "en": "Warning"},
    "zone_danger": {"id": "Bahaya", "en": "Danger"},
    "lang_switch": {"id": "EN", "en": "ID"},
    "last_update": {"id": "Update terakhir", "en": "Last update"},
    "no_data": {"id": "Menunggu data dari sensor...", "en": "Waiting for sensor data..."},
    "device": {"id": "Perangkat", "en": "Device"},
}

def t(key: str, lang: str) -> str:
    return TEXTS.get(key, {}).get(lang, TEXTS.get(key, {}).get("en", key))
