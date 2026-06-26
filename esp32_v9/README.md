# SmartQuail ESP32 Firmware v9.0

**Firmware kandang puyuh cerdas untuk ESP32** — membaca sensor, kontrol aktuator, terhubung ke Firebase Realtime Database via Stream.

---

## Hardware

| Komponen | Pin ESP32 | Fungsi |
|----------|-----------|--------|
| DHT22 | GPIO 4 | Sensor suhu & kelembaban |
| MQ-135 | GPIO 33 (ADC) | Sensor gas amonia (NH3) |
| Relay 1 | GPIO 26 | Kipas (active LOW) |
| Relay 2 | GPIO 27 | Pompa air (active LOW) |
| Servo SG90 | GPIO 18 | Auto-feeder |
| Nextion LCD | RX 16, TX 17 | UI hardware kandang (baud 9600) |
| RTC DS1307 | I2C (SDA 21, SCL 22) | Jam real-time (backup) |

---

## Fitur Utama

### Firebase Stream (bukan polling)
Kontrol dari Flutter app diterima secara real-time push — tidak perlu tanya terus-menerus. Hemat bandwidth & Firebase quota.

### Smart Data Send
Data sensor dikirim ke Firebase hanya saat nilai berubah (suhu ±0.3°C, kelembaban ±1%, amonia ±1ppm). Tetap kirim keep-alive minimal 30 detik sekali.

### Non-Blocking Feeder
Feeder pakai state machine — tidak ada delay() yang membekukan loop. ESP32 tetap bisa baca sensor dan Firebase selama feeding berlangsung.

### THI Formula Standar
THI = T - 0.55 x (1 - H/100) x (T - 14.5)
Dimana T = suhu (°C), H = kelembaban relatif (%)

### History ke Firebase
Setiap 5 menit, data sensor ditulis ke /history/YYYY-MM-DD/HH:MM/ dengan format {t, h, a, thi, f, p}

### Watchdog Timer
ESP32 auto-restart jika loop() freeze lebih dari 10 detik.

### Exponential Backoff Reconnect
Kalau Firebase putus, reconnect dengan jeda: 1s -> 2s -> 4s -> 8s -> 16s -> ... -> max 60s.

### Nextion LCD
Tombol fisik di kandang:
| Tombol | Fungsi |
|--------|--------|
| 1 | Fan ON |
| 2 | Fan OFF |
| 3 | Pump ON |
| 4 | Pump OFF |
| 5 | Feed sekarang |

Cooldown 300ms anti double-trigger.

### Jadwal Feeder Otomatis
Default 3x sehari: 07:00, 12:00, 17:00. Reset flag di tengah malam. Jadwal bisa diubah dari Firebase /controls/feed_hour1..3 & /controls/feed_min1..3.

### onDisconnect Auto-Offline
Saat ESP32 mati atau putus WiFi, Firebase otomatis set /sensor_data/online = false.

### Logging dengan Timestamp
Semua log ke Serial Monitor punya timestamp:
[14:30:05] [Sensor] T=28.5 H=70 NH3=12 THI=74.1
[14:30:05] [Firebase] Data sent OK
[14:35:00] [History] Saved: history/2026-06-25/14:35

---

## Library Arduino IDE

Install via Library Manager (Sketch -> Include Library -> Manage Libraries):

| Library | Author |
|---------|--------|
| Firebase ESP32 Client | Mobizt |
| DHT sensor library | Adafruit |
| RTClib | Adafruit |
| ESP32Servo | Kevin Harrington |

Library WiFi.h, Wire.h, time.h, esp_task_wdt.h sudah built-in di ESP32 core.

---

## Konfigurasi

Buka file .ino, ubah bagian KONFIGURASI:

// WiFi
WIFI_SSID = "nama_wifi_kamu"
WIFI_PASSWORD = "password_wifi_kamu"

// Firebase
FIREBASE_HOST = "smartquail-18658-default-rtdb.asia-southeast1.firebasedatabase.app"
FIREBASE_API_KEY = "AIzaSy..."  // dapatkan dari Firebase Console

// Device ID
DEVICE_ID = "ESP32-01"

### Timing (opsional)
SENSOR_INTERVAL = 2000       // baca sensor tiap 2 detik
FIREBASE_SEND_INTERVAL = 5000 // cek kirim tiap 5 detik
HISTORY_INTERVAL = 300000     // simpan history tiap 5 menit

### Jadwal Feeder (opsional)
feedHour1 = 7;  feedMin1 = 0;   // pagi
feedHour2 = 12; feedMin2 = 0;   // siang
feedHour3 = 17; feedMin3 = 0;   // sore

---

## Firebase Realtime Database Structure

### ESP32 menulis ke:

/sensor_data (updateNode — patch, bukan replace)
{
  "temperature": 28.5,
  "humidity": 70,
  "ammonia": 12,
  "thi": 74.1,
  "relay_fan": false,
  "relay_pump": false,
  "online": true,
  "timestamp": 1716178800,
  "hour": 14,
  "minute": 30,
  "device_id": "ESP32-01"
}

/history/YYYY-MM-DD/HH:MM (setJSON per 5 menit)
{
  "t": 28.5,
  "h": 70,
  "a": 12,
  "thi": 74.1,
  "f": 0,
  "p": 0
}

### ESP32 membaca dari (Stream):

/controls — ditulis oleh Flutter app
{
  "fan": false,
  "pump": false,
  "feed_now": false,
  "feed_hour1": 7,  "feed_min1": 0,
  "feed_hour2": 12, "feed_min2": 0,
  "feed_hour3": 17, "feed_min3": 0
}

---

## Cara Upload

1. Buka Arduino IDE
2. Install semua library di atas
3. Pilih board: ESP32 Dev Module
4. Update konfigurasi WiFi & Firebase di bagian atas kode
5. Upload

---

## Serial Monitor

Baud rate: 115200

Output normal:
[14:00:00] [SYSTEM] SmartQuail v9.0 Ready!
[14:00:02] [Sensor] T=28.5 H=70 NH3=12 THI=74.1
[14:00:05] [Firebase] Data sent OK
[14:00:05] [Stream] listening on /controls
[14:05:00] [History] Saved: history/2026-06-25/14:05

---

## Troubleshooting

| Masalah | Cek |
|---------|-----|
| History tidak muncul | Pastikan NTP sync sukses ([NTP] Synced), tunggu 5 menit |
| Sensor selalu 0 | Cek wiring DHT22, pastikan [DHT] Init muncul |
| Amonia 0 terus | Sensor MQ-135 perlu warmup 24-48 jam pertama |
| Fan/pump tidak merespon | Cek relay active-LOW (LOW = ON, HIGH = OFF) |
| Firebase gagal connect | Cek WiFi SSID/password, cek API key, cek rules database |
| ESP32 restart terus | Cek watchdog log [WDT], kemungkinan loop freeze |

---

## Changelog

### v9.0 (current)
- Hapus semua kode LED
- Stream callback: tambah .success guard di semua field
- MQ-135: guard raw < 10 untuk sensor belum warmup
- Bersihkan dari GPIO strapping pin

### v8.0
- Stream ganti polling (real-time /controls)
- Non-blocking feeder (state machine)
- Rumus THI standar
- History time key "HH:MM" (pakai ":")
- Watchdog timer 10 detik
- Exponential backoff reconnect
- Smart data send (threshold-based)
- updateNode ganti setJSON (field last_feed tidak terhapus)
- Logging dengan timestamp
- Tambah hour, minute, device_id di sensor data

### v6.0 (sebelumnya)
- Polling readControls() tiap 3 detik
- Feeder blocking (delay(1500))
- Rumus THI non-standar
- History time key "HHMM" (tanpa ":")
- Tanpa watchdog
