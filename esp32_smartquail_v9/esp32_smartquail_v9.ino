#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <DHT.h>
#include <Wire.h>
#include <RTClib.h>
#include <ESP32Servo.h>
#include <time.h>
#include <esp_task_wdt.h>

#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

// ============================================================
// KONFIGURASI
// ============================================================
#define WIFI_SSID     "BINUS-IoT"
#define WIFI_PASSWORD "Binus-10T!"

#define FIREBASE_HOST    "smartquail-18658-default-rtdb.asia-southeast1.firebasedatabase.app"
#define FIREBASE_API_KEY "AIzaSyAxtACANl6k0S3b_QOjxQtSLc6-4u4EqiQ"

#define DEVICE_ID "ESP32-01"

// ============================================================
// PIN
// ============================================================
#define DHT_PIN   4
#define DHT_TYPE  DHT22
#define MQ135_PIN 33
#define RELAY_FAN  26
#define RELAY_PUMP 27
#define SERVO_PIN  18

// ============================================================
// NEXTION
// ============================================================
#define NEXTION_RX   16
#define NEXTION_TX   17
#define NEXTION_BAUD 9600

// ============================================================
// TIMING
// ============================================================
#define SENSOR_INTERVAL        2000
#define FIREBASE_SEND_INTERVAL 5000
#define HISTORY_INTERVAL       300000
#define RECONNECT_INTERVAL     30000
#define COOLDOWN               300
#define WDT_TIMEOUT_S          10

// Exponential backoff Firebase
#define FB_BACKOFF_MIN  1000UL
#define FB_BACKOFF_MAX  60000UL

// Deteksi versi core ESP32 untuk API watchdog
#if defined(ESP_ARDUINO_VERSION) && defined(ESP_ARDUINO_VERSION_VAL)
  #if ESP_ARDUINO_VERSION >= ESP_ARDUINO_VERSION_VAL(3, 0, 0)
    #define WDT_CORE3
  #endif
#endif

// ============================================================
// OBJECTS
// ============================================================
DHT        dht(DHT_PIN, DHT_TYPE);
RTC_DS1307 rtc;
Servo      feederServo;

FirebaseData   fbdo;
FirebaseData   stream;
FirebaseAuth   auth;
FirebaseConfig config;

// ============================================================
// PATH FIREBASE
// ============================================================
String PATH_SENSOR   = "sensor_data";
String PATH_CONTROLS = "controls";
String PATH_HISTORY  = "history";

// ============================================================
// VARIABEL GLOBAL
// ============================================================
float temperature = 0, humidity = 0, ammoniaPPM = 0, thi = 0;

bool fanState  = false;
bool pumpState = false;
int  fanSpeed  = 0;
bool isFeeding = false;
volatile bool feedRequested = false;

int  feedHour1 = 7,  feedMin1 = 0;
int  feedHour2 = 12, feedMin2 = 0;
int  feedHour3 = 17, feedMin3 = 0;
bool fedToday1 = false, fedToday2 = false, fedToday3 = false;

unsigned long lastSensorRead   = 0;
unsigned long lastFirebaseSend = 0;
unsigned long lastHistorySave  = 0;
unsigned long lastReconnect    = 0;
unsigned long lastFanCmd       = 0;
unsigned long lastPumpCmd      = 0;

bool firebaseConnected = false;
bool wifiConnected     = false;
bool streamStarted     = false;
bool fbNeedsReconnect  = false;
int  firebaseErrors    = 0;

unsigned long fbBackoff   = FB_BACKOFF_MIN;
unsigned long lastFbRetry = 0;

int    currentHour = 0, currentMinute = 0, currentSecond = 0;
String currentDate = "";

// Feeder non-blocking state machine
enum FeedState { FEED_IDLE, FEED_OPENING, FEED_HOLDING, FEED_CLOSING };
FeedState     feedState = FEED_IDLE;
unsigned long feedTimer = 0;

// forward declarations
void setupFirebase();
void startControlStream();
void startFeeder();

// ============================================================
// LOGGING dengan timestamp
// ============================================================
String tstamp() {
  char b[12];
  sprintf(b, "[%02d:%02d:%02d] ", currentHour, currentMinute, currentSecond);
  return String(b);
}
void logMsg(const String &m) { Serial.println(tstamp() + m); }

// ============================================================
// NEXTION SEND
// ============================================================
void nextionSend(String cmd) {
  Serial2.print(cmd);
  Serial2.write(0xFF); Serial2.write(0xFF); Serial2.write(0xFF);
}

// ============================================================
// APPLY RELAY (hardware saja, TANPA echo Firebase)
// ============================================================
void applyFan(bool v) {
  fanState = v;
  fanSpeed = v ? 100 : 0;
  digitalWrite(RELAY_FAN, v ? LOW : HIGH);
}
void applyPump(bool v) {
  pumpState = v;
  digitalWrite(RELAY_PUMP, v ? LOW : HIGH);
}

void setFanSpeed(int pct) {
  pct = constrain(pct, 0, 100);
  fanSpeed = pct;
  fanState = (pct > 0);
  digitalWrite(RELAY_FAN, fanState ? LOW : HIGH);
}

// ============================================================
// SET RELAY (hardware + echo ke Firebase)
// ============================================================
void setFan(bool state) {
  applyFan(state);
  logMsg("[Fan] " + String(state ? "ON" : "OFF"));
  if (firebaseConnected) {
    Firebase.RTDB.setBool(&fbdo, PATH_CONTROLS + "/fan", state);
    Firebase.RTDB.setInt(&fbdo,  PATH_CONTROLS + "/fan_speed", fanSpeed);
  }
}
void setPump(bool state) {
  applyPump(state);
  logMsg("[Pump] " + String(state ? "ON" : "OFF"));
  if (firebaseConnected)
    Firebase.RTDB.setBool(&fbdo, PATH_CONTROLS + "/pump", state);
}

// ============================================================
// FEEDER — NON-BLOCKING
// ============================================================
void startFeeder() {
  if (isFeeding) return;
  isFeeding = true;
  feederServo.attach(SERVO_PIN);
  feedState = FEED_OPENING;
  feedTimer = millis();
  logMsg("[Feeder] Aktivasi...");
}

void updateFeeder() {
  if (!isFeeding) return;
  unsigned long now = millis();
  switch (feedState) {
    case FEED_OPENING:
      if (now - feedTimer >= 100) {
        feederServo.write(90);
        feedState = FEED_HOLDING;
        feedTimer = now;
      }
      break;
    case FEED_HOLDING:
      if (now - feedTimer >= 1500) {
        feederServo.write(0);
        feedState = FEED_CLOSING;
        feedTimer = now;
      }
      break;
    case FEED_CLOSING:
      if (now - feedTimer >= 500) {
        feederServo.detach();
        feedState = FEED_IDLE;
        isFeeding = false;
        logMsg("[Feeder] Done");
      }
      break;
    default: break;
  }
}

void checkFeederSchedule() {
  if (currentHour == 0 && currentMinute == 0)
    fedToday1 = fedToday2 = fedToday3 = false;

  if (currentHour == feedHour1 && currentMinute == feedMin1 && !fedToday1) {
    fedToday1 = true; logMsg("[Feeder] Jadwal 1"); startFeeder();
    if (firebaseConnected)
      Firebase.RTDB.setString(&fbdo, PATH_SENSOR + "/last_feed",
        String(feedHour1) + ":" + (feedMin1 < 10 ? "0" : "") + String(feedMin1));
  }
  if (currentHour == feedHour2 && currentMinute == feedMin2 && !fedToday2) {
    fedToday2 = true; logMsg("[Feeder] Jadwal 2"); startFeeder();
    if (firebaseConnected)
      Firebase.RTDB.setString(&fbdo, PATH_SENSOR + "/last_feed",
        String(feedHour2) + ":" + (feedMin2 < 10 ? "0" : "") + String(feedMin2));
  }
  if (currentHour == feedHour3 && currentMinute == feedMin3 && !fedToday3) {
    fedToday3 = true; logMsg("[Feeder] Jadwal 3"); startFeeder();
    if (firebaseConnected)
      Firebase.RTDB.setString(&fbdo, PATH_SENSOR + "/last_feed",
        String(feedHour3) + ":" + (feedMin3 < 10 ? "0" : "") + String(feedMin3));
  }
}

// ============================================================
// NEXTION — BACA COMMAND
// ============================================================
void readNextionCommands() {
  while (Serial2.available()) {
    uint8_t c = Serial2.read();
    unsigned long now = millis();

    if (c == '1') {
      if (now - lastFanCmd >= COOLDOWN && !fanState) {
        lastFanCmd = now;
        setFan(true);
      }
    }
    else if (c == '2') {
      if (now - lastFanCmd >= COOLDOWN && fanState) {
        lastFanCmd = now;
        setFan(false);
      }
    }
    else if (c == '3') {
      if (now - lastPumpCmd >= COOLDOWN && !pumpState) {
        lastPumpCmd = now;
        setPump(true);
      }
    }
    else if (c == '4') {
      if (now - lastPumpCmd >= COOLDOWN && pumpState) {
        lastPumpCmd = now;
        setPump(false);
      }
    }
    else if (c == '5') {
      startFeeder();
    }
  }
}

// ============================================================
// STREAM /controls
// ============================================================
void streamCallback(FirebaseStream data) {
  String path = data.dataPath();

  if (path == "/") {
    FirebaseJson &j = data.jsonObject();
    FirebaseJsonData d;
    if (j.get(d, "fan")        && d.success) applyFan(d.to<bool>());
    if (j.get(d, "pump")       && d.success) applyPump(d.to<bool>());
    if (j.get(d, "feed_now")   && d.success && d.to<bool>()) feedRequested = true;
    if (j.get(d, "feed_hour1") && d.success) feedHour1 = d.to<int>();
    if (j.get(d, "feed_min1")  && d.success) feedMin1  = d.to<int>();
    if (j.get(d, "feed_hour2") && d.success) feedHour2 = d.to<int>();
    if (j.get(d, "feed_min2")  && d.success) feedMin2  = d.to<int>();
    if (j.get(d, "feed_hour3") && d.success) feedHour3 = d.to<int>();
    if (j.get(d, "feed_min3")  && d.success) feedMin3  = d.to<int>();
    return;
  }

  String key = path.substring(1);
  if      (key == "fan")        applyFan(data.boolData());
  else if (key == "pump")       applyPump(data.boolData());
  else if (key == "feed_now")   { if (data.boolData()) feedRequested = true; }
  else if (key == "feed_hour1") feedHour1 = data.intData();
  else if (key == "feed_min1")  feedMin1  = data.intData();
  else if (key == "feed_hour2") feedHour2 = data.intData();
  else if (key == "feed_min2")  feedMin2  = data.intData();
  else if (key == "feed_hour3") feedHour3 = data.intData();
  else if (key == "feed_min3")  feedMin3  = data.intData();
}

void streamTimeoutCallback(bool timeout) {
  if (timeout) logMsg("[Stream] timeout, auto-resume...");
  if (!stream.httpConnected())
    logMsg("[Stream] err: " + stream.errorReason());
}

void startControlStream() {
  stream.setBSSLBufferSize(2048, 1024);
  if (!Firebase.RTDB.beginStream(&stream, PATH_CONTROLS))
    logMsg("[Stream] begin error: " + stream.errorReason());
  Firebase.RTDB.setStreamCallback(&stream, streamCallback, streamTimeoutCallback);
  streamStarted = true;
  logMsg("[Stream] listening on /controls");
}

// ============================================================
// SENSOR
// ============================================================
void readSensors() {
  float t = dht.readTemperature();
  float h = dht.readHumidity();

  if (!isnan(t) && !isnan(h)) {
    temperature = t;
    humidity    = h;
    thi = temperature - 0.55 * (1.0 - humidity / 100.0) * (temperature - 14.5);
  } else {
    logMsg("[Sensor] DHT gagal baca!");
  }

  int raw = analogRead(MQ135_PIN);
  if (raw < 10) {
    ammoniaPPM = 0.0;
  } else {
    ammoniaPPM = constrain(map(raw, 0, 4095, 0, 100), 0, 100);
  }

  char buf[80];
  snprintf(buf, sizeof(buf), "[Sensor] T=%.1f H=%.0f NH3=%.0f THI=%.1f",
           temperature, humidity, ammoniaPPM, thi);
  logMsg(String(buf));
}

// ============================================================
// FIREBASE — SMART SEND
// ============================================================
void sendSensorData() {
  static float lastT = -100, lastH = -100, lastA = -100;
  static unsigned long lastForce = 0;
  unsigned long now = millis();

  bool changed = fabs(temperature - lastT) >= 0.3 ||
                 fabs(humidity    - lastH) >= 1.0 ||
                 fabs(ammoniaPPM  - lastA) >= 1.0;
  bool keepAlive = now - lastForce >= 30000;
  if (!changed && !keepAlive) return;

  FirebaseJson json;
  json.set("temperature", round(temperature * 10) / 10.0);
  json.set("humidity",    round(humidity));
  json.set("ammonia",     round(ammoniaPPM));
  json.set("thi",         round(thi * 10) / 10.0);
  json.set("relay_fan",   fanState);
  json.set("relay_pump",  pumpState);
  json.set("online",      true);
  json.set("timestamp",   (int)(millis() / 1000));
  json.set("hour",        currentHour);
  json.set("minute",      currentMinute);
  json.set("device_id",   DEVICE_ID);

  if (Firebase.RTDB.updateNode(&fbdo, PATH_SENSOR, &json)) {
    logMsg("[Firebase] Data sent OK");
    lastT = temperature; lastH = humidity; lastA = ammoniaPPM; lastForce = now;
    firebaseErrors = 0;
  } else {
    firebaseErrors++;
    logMsg("[Firebase] FAILED: " + fbdo.errorReason());
    if (firebaseErrors > 10) { fbNeedsReconnect = true; firebaseErrors = 0; }
  }
}

void saveHistory() {
  if (currentDate.length() == 0) return;

  // Validasi: tolak tanggal/jam invalid (RTC rusak, NTP belum sync, dll)
  if (currentDate.length() != 10 || currentDate[4] != '-' ||
      currentHour > 23 || currentMinute > 59) {
    logMsg("[History] REJECTED: invalid date/time (hour=" +
           String(currentHour) + " min=" + String(currentMinute) + ")");
    return;
  }

  String timeKey = (currentHour   < 10 ? "0" : "") + String(currentHour)   + ":"
                 + (currentMinute < 10 ? "0" : "") + String(currentMinute);
  String path = PATH_HISTORY + "/" + currentDate + "/" + timeKey;

  FirebaseJson json;
  json.set("t",   round(temperature * 10) / 10.0);
  json.set("h",   round(humidity));
  json.set("a",   round(ammoniaPPM));
  json.set("thi", round(thi * 10) / 10.0);
  json.set("f",   fanState  ? 1 : 0);
  json.set("p",   pumpState ? 1 : 0);
  json.set("ts",  (int)time(nullptr));

  if (Firebase.RTDB.setJSON(&fbdo, path, &json))
    logMsg("[History] Saved: " + path);
}

void setupFirebase() {
  logMsg("[Firebase] Setting up...");
  config.database_url           = FIREBASE_HOST;
  config.api_key                = FIREBASE_API_KEY;
  auth.user.email               = "";
  auth.user.password            = "";
  config.signer.test_mode       = true;
  config.token_status_callback  = tokenStatusCallback;
  config.timeout.serverResponse = 10 * 1000;

  Firebase.reconnectNetwork(true);
  fbdo.setBSSLBufferSize(2048, 1024);
  Firebase.begin(&config, &auth);
  delay(2000);

  if (Firebase.ready()) {
    firebaseConnected = true;
    fbNeedsReconnect  = false;
    firebaseErrors    = 0;
    logMsg("[Firebase] CONNECTED!");

    Firebase.RTDB.setBool(&fbdo, PATH_SENSOR + "/online", true);

    if (!streamStarted) startControlStream();
  } else {
    firebaseConnected = false;
    logMsg("[Firebase] Failed, will retry...");
  }
}

// ============================================================
// WIFI
// ============================================================
void connectWiFi() {
  Serial.print("[WiFi] Connecting...");
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500); Serial.print("."); attempts++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    wifiConnected = true;
    Serial.println("\n[WiFi] Connected! IP: " + WiFi.localIP().toString());
  } else {
    wifiConnected = false;
    Serial.println("\n[WiFi] GAGAL! Lanjut tanpa WiFi.");
  }
}

// ============================================================
// WAKTU — NTP primary (RTC TIDAK digunakan sebagai sumber waktu)
// ============================================================
void updateTime() {
  struct tm timeinfo;
  if (getLocalTime(&timeinfo)) {
    currentHour   = timeinfo.tm_hour;
    currentMinute = timeinfo.tm_min;
    currentSecond = timeinfo.tm_sec;
    char buf[11];
    sprintf(buf, "%04d-%02d-%02d",
            timeinfo.tm_year + 1900, timeinfo.tm_mon + 1, timeinfo.tm_mday);
    currentDate = String(buf);
  }
  // NTP gagal? Pakai nilai terakhir — tidak overwrite dengan garbage RTC
}

// ============================================================
// SETUP
// ============================================================
void setup() {
  Serial.begin(115200);
  Serial.println("\n================================");
  Serial.println(" SmartQuail v9.1");
  Serial.println(" Device: " + String(DEVICE_ID));
  Serial.println("================================\n");

  // Relay — set OFF
  pinMode(RELAY_FAN,  OUTPUT);
  pinMode(RELAY_PUMP, OUTPUT);
  applyFan(false);
  applyPump(false);

  // Servo
  feederServo.attach(SERVO_PIN);
  feederServo.write(0);
  delay(300);
  feederServo.detach();

  // DHT
  dht.begin();
  Serial.println("[DHT] Init, warmup 2s...");
  delay(2000);

  // Nextion
  Serial2.begin(NEXTION_BAUD, SERIAL_8N1, NEXTION_RX, NEXTION_TX);
  delay(500);
  while (Serial2.available()) Serial2.read();
  Serial.println("[Nextion] Ready");

  // RTC — opsional (tidak blocking, tidak dipakai untuk updateTime)
  Wire.begin();
  if (rtc.begin()) {
    Serial.println("[RTC] OK (optional — not used as primary time source)");
    if (!rtc.isrunning())
      rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
  } else {
    Serial.println("[RTC] Not found — OK, using NTP only");
  }

  // WiFi
  connectWiFi();

  // NTP — sumber waktu utama
  if (wifiConnected) {
    configTime(7 * 3600, 0, "pool.ntp.org", "time.nist.gov");
    int ntpRetry = 0;
    struct tm timeinfo;
    while (!getLocalTime(&timeinfo) && ntpRetry < 10) {
      delay(1000); ntpRetry++;
    }
    if (ntpRetry < 10) {
      Serial.println("[NTP] Synced!");
      // Sinkronkan RTC (kalau ada) dari NTP — optional
      if (rtc.begin()) {
        rtc.adjust(DateTime(
          timeinfo.tm_year + 1900, timeinfo.tm_mon + 1, timeinfo.tm_mday,
          timeinfo.tm_hour, timeinfo.tm_min, timeinfo.tm_sec));
      }
      updateTime();   // <-- baca langsung dari getLocalTime(), bukan RTC
    } else {
      Serial.println("[NTP] GAGAL sync — history disabled until WiFi stable");
    }
  } else {
    logMsg("[WAKTU] WiFi gagal, history disabled sampai WiFi tersedia");
  }

  // Firebase
  setupFirebase();

  // Watchdog
#ifdef WDT_CORE3
  esp_task_wdt_config_t wdtCfg = {
    .timeout_ms     = WDT_TIMEOUT_S * 1000,
    .idle_core_mask = 0,
    .trigger_panic  = true
  };
  esp_task_wdt_init(&wdtCfg);
#else
  esp_task_wdt_init(WDT_TIMEOUT_S, true);
#endif
  esp_task_wdt_add(NULL);
  logMsg("[WDT] Watchdog aktif (" + String(WDT_TIMEOUT_S) + "s)");

  logMsg("[SYSTEM] SmartQuail v9.1 Ready!");
  Serial.println("Nextion: 1=FAN ON 2=FAN OFF 3=PUMP ON 4=PUMP OFF 5=FEED\n");
}

// ============================================================
// LOOP
// ============================================================
void loop() {
  unsigned long now = millis();

  // WiFi check
  if (WiFi.status() != WL_CONNECTED) {
    wifiConnected = false;
    if (now - lastReconnect > RECONNECT_INTERVAL) {
      lastReconnect = now;
      WiFi.reconnect();
    }
  } else {
    wifiConnected = true;
  }

  // Sensor
  if (now - lastSensorRead >= SENSOR_INTERVAL) {
    lastSensorRead = now;
    readSensors();
  }

  // Nextion button
  readNextionCommands();

  // Feeder state machine
  updateFeeder();

  // Jadwal feeder
  checkFeederSchedule();

  // Feed dari Flutter (stream)
  if (feedRequested) {
    feedRequested = false;
    startFeeder();
    if (firebaseConnected) {
      Firebase.RTDB.setBool(&fbdo,   PATH_CONTROLS + "/feed_now", false);
      Firebase.RTDB.setString(&fbdo, PATH_SENSOR   + "/last_feed", "manual");
    }
  }

  // Firebase
  if (wifiConnected && Firebase.ready() && !fbNeedsReconnect) {
    firebaseConnected = true;
    fbBackoff = FB_BACKOFF_MIN;

    if (now - lastFirebaseSend >= FIREBASE_SEND_INTERVAL) {
      lastFirebaseSend = now;
      sendSensorData();
    }
    if (now - lastHistorySave >= HISTORY_INTERVAL) {
      lastHistorySave = now;
      saveHistory();
    }
  }
  else if (wifiConnected) {
    firebaseConnected = false;
    if (now - lastFbRetry >= fbBackoff) {
      lastFbRetry = now;
      logMsg("[Firebase] Reconnect (backoff " + String(fbBackoff / 1000) + "s)");
      setupFirebase();
      if (firebaseConnected) fbBackoff = FB_BACKOFF_MIN;
      else fbBackoff = min(fbBackoff * 2UL, FB_BACKOFF_MAX);
    }
  }
  else {
    firebaseConnected = false;
  }

  updateTime();
  esp_task_wdt_reset();
}
