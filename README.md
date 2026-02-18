# 🐦 SmartQuail – IoT Dashboard Kandang Puyuh

Dashboard Streamlit untuk memantau suhu, kelembapan, dan THI dari sensor ESP32 via MQTT. Data disimpan di Supabase dan ditampilkan dengan tampilan mirip Apple (bersih, responsif, bilingual).

## Fitur

- **KPI cards**: Suhu (°C), Kelembapan (%), THI, Status Relay (ON/OFF)
- **Status bar**: Aman / Waspada / Bahaya berdasarkan THI (<72, 72–78, >78)
- **Grafik tren**: Suhu & kelembapan (1 jam terakhir)
- **Gauge THI**: Zona Normal / Warning / Danger
- **Bahasa**: Indonesia & English (toggle)
- **Auto-refresh**: Setiap 2 detik
- **MQTT**: HiveMQ `broker.hivemq.com`, topic `iot/smartquail/dht`
- **Storage**: Supabase (history 24 jam)

## Setup Supabase

1. Buat project di [supabase.com](https://supabase.com).
2. Di **SQL Editor** jalankan:

```sql
create table if not exists readings (
  id uuid default gen_random_uuid() primary key,
  device text not null,
  temp float not null,
  rh float not null,
  thi float not null,
  relay text not null,
  status text not null,
  created_at timestamptz default now()
);

create index if not exists idx_readings_device_created on readings(device, created_at desc);
```

3. Di **Project Settings → API**: copy **Project URL** dan **anon public** key.

## Jalankan Lokal

```bash
# Clone / masuk folder
cd SmartQuail

# Virtual env (opsional)
python -m venv venv
venv\Scripts\activate   # Windows
# source venv/bin/activate  # Mac/Linux

# Install
pip install -r requirements.txt

# Set env (atau buat file .env)
set SUPABASE_URL=https://xxx.supabase.co
set SUPABASE_KEY=eyJ...

# Run
streamlit run app.py
```

Tanpa `SUPABASE_URL`/`SUPABASE_KEY`, dashboard tetap jalan dengan **data demo** (satu baris contoh).

## Deploy di Streamlit Cloud

1. Push repo ke GitHub.
2. [share.streamlit.io](https://share.streamlit.io) → New app → pilih repo `SmartQuail`, file `app.py`.
3. **Secrets** (Settings → Secrets):

```toml
SUPABASE_URL = "https://xxx.supabase.co"
SUPABASE_KEY = "eyJ..."
```

4. Deploy. MQTT subscriber jalan di dalam app dan menulis ke Supabase; browser hanya baca dari Supabase setiap 2 detik.

## Format Data MQTT

Topic: `iot/smartquail/dht`  
Payload JSON:

```json
{
  "device": "esp32-01",
  "temp": 28.3,
  "rh": 72,
  "thi": 78.9,
  "relay": "ON",
  "status": "OK"
}
```

## Logo

Letakkan file **smartquail.png** di root folder (sejajar dengan `app.py`). Kalau tidak ada, akan dipakai emoji 🐦 sebagai placeholder.

## File Penting

| File | Fungsi |
|------|--------|
| `app.py` | Dashboard Streamlit (UI, grafik, bahasa) |
| `config.py` | Konfigurasi (Supabase, MQTT, interval, batas THI) |
| `supabase_client.py` | Baca/tulis data ke Supabase |
| `mqtt_listener.py` | Subscribe MQTT → insert ke Supabase |
| `i18n.py` | Teks ID/EN |

## Lisensi

MIT.
