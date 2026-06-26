/*
 * SmartQuail - ESP32 Firmware for Quail Cage Monitoring & Control
 * ----------------------------------------------------------------------
 * Hardware:
 *   - ESP32 Dev Board
 *   - DHT22 (temperature & humidity) on GPIO 4
 *   - MQ-135 (ammonia gas sensor) on GPIO 34 (ADC)
 *   - MOSFET PWM for fan control on GPIO 25
 *   - Relay 1: Water Pump on GPIO 26
 *   - Relay 2: Auto Feeder on GPIO 27
 *
 * Firebase Realtime Database paths (V5.0):
 *   /sensor_data   <- ESP32 writes sensor readings & relay status
 *   /controls      <- ESP32 reads user commands
 *   /history       <- ESP32 writes time-series records
 *
 * Dependencies (Arduino Library Manager):
 *   - Firebase ESP32 Client by Mobizt
 *   - DHT sensor library by Adafruit
 *   - MQ135 library (optional, or use raw ADC formula)
 *
 * THI Formula: THI = T - 0.55 * (1 - RH/100) * (T - 14.5)
 *   T = temperature (C),  RH = relative humidity (%)
 * ----------------------------------------------------------------------
 */

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <DHT.h>
#include "time.h"

// ===================== CONFIGURATION =====================
#define WIFI_SSID       "YOUR_WIFI_SSID"
#define WIFI_PASSWORD   "YOUR_WIFI_PASSWORD"

#define FIREBASE_HOST   "smartquail-18658-default-rtdb.asia-southeast1.firebasedatabase.app"
#define FIREBASE_AUTH   "YOUR_DATABASE_SECRET"

#define DHTPIN          4
#define DHTTYPE         DHT22
#define MQ135_PIN       34
#define FAN_PWM_PIN     25
#define PUMP_RELAY_PIN  26
#define FEEDER_RELAY_PIN 27

#define UPDATE_INTERVAL  5000
#define HISTORY_INTERVAL 300000

// NTP settings (Indonesia = GMT+7)
#define GMT_OFFSET_SEC   25200
#define DAYLIGHT_OFFSET  0

// ===================== OBJECTS =====================
DHT dht(DHTPIN, DHTTYPE);
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// ===================== GLOBALS =====================
unsigned long lastUpdate = 0;
unsigned long lastHistoryWrite = 0;
unsigned long feedStartTime = 0;
bool feedActive = false;
bool fanState = false;
bool pumpState = false;

// ===================== FUNCTION PROTOTYPES =====================
void connectWiFi();
void syncNTP();
void setupFirebase();
float readTemperature();
float readHumidity();
float readAmmonia();
float calculateTHI(float temp, float humidity);
void writeSensorData(float temp, float hum, float thi, float nh3, bool fan, bool pump, bool online);
void writeHistory(float temp, float hum, float thi, float nh3, bool fan, bool pump);
void readControls();
void executeControl(bool fan, bool pump);
void startFeeding();
void checkFeedStatus();

// ===================== SETUP =====================
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n===================================");
  Serial.println(" SmartQuail ESP32 Firmware v5.0");
  Serial.println("===================================");

  dht.begin();
  pinMode(MQ135_PIN, INPUT);
  pinMode(FAN_PWM_PIN, OUTPUT);
  pinMode(PUMP_RELAY_PIN, OUTPUT);
  pinMode(FEEDER_RELAY_PIN, OUTPUT);
  digitalWrite(FAN_PWM_PIN, LOW);
  digitalWrite(PUMP_RELAY_PIN, LOW);
  digitalWrite(FEEDER_RELAY_PIN, LOW);

  connectWiFi();
  syncNTP();
  setupFirebase();
}

// ===================== LOOP =====================
void loop() {
  unsigned long now = millis();

  readControls();
  checkFeedStatus();

  if (now - lastUpdate >= UPDATE_INTERVAL) {
    lastUpdate = now;

    float temp = readTemperature();
    float hum  = readHumidity();
    float nh3  = readAmmonia();
    float thi  = calculateTHI(temp, hum);

    Serial.printf("[SENSOR] T=%.1fC  H=%.1f%%  THI=%.1f  NH3=%.1fppm  Fan=%d  Pump=%d\n",
                  temp, hum, thi, nh3, fanState, pumpState);

    writeSensorData(temp, hum, thi, nh3, fanState, pumpState, true);

    if (now - lastHistoryWrite >= HISTORY_INTERVAL) {
      lastHistoryWrite = now;
      writeHistory(temp, hum, thi, nh3, fanState, pumpState);
    }
  }
}

// ===================== WiFi =====================
void connectWiFi() {
  Serial.printf("Connecting to WiFi: %s\n", WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.printf("\nWiFi connected. IP: %s\n", WiFi.localIP().toString().c_str());
}

// ===================== NTP Time Sync =====================
void syncNTP() {
  Serial.print("Syncing NTP time...");
  configTime(GMT_OFFSET_SEC, DAYLIGHT_OFFSET, "pool.ntp.org", "time.nist.gov");

  struct tm timeinfo;
  int retry = 0;
  while (!getLocalTime(&timeinfo) && retry < 10) {
    delay(500);
    Serial.print(".");
    retry++;
  }

  if (retry >= 10) {
    Serial.println("\n[WARN] NTP sync failed. History will not be written.");
    return;
  }

  char buf[64];
  strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S", &timeinfo);
  Serial.printf("\nNTP synced: %s\n", buf);
}

// ===================== Firebase Setup =====================
void setupFirebase() {
  config.database_url = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;
  fbdo.setResponseSize(4096);
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  Serial.println("Firebase initialized.");
}

// ===================== SENSOR READING =====================
float readTemperature() {
  float t = dht.readTemperature();
  if (isnan(t)) {
    Serial.println("[WARN] DHT22 temperature read failed!");
    return 0.0;
  }
  return t;
}

float readHumidity() {
  float h = dht.readHumidity();
  if (isnan(h)) {
    Serial.println("[WARN] DHT22 humidity read failed!");
    return 0.0;
  }
  return h;
}

float readAmmonia() {
  int raw = analogRead(MQ135_PIN);
  float voltage = raw * (3.3 / 4095.0);

  // Guard: division by zero when sensor not ready
  if (voltage < 0.05) return 0.0;

  float rs = (3.3 - voltage) / voltage;
  float ppm = rs * 10.0;
  return ppm;
}

float calculateTHI(float temp, float humidity) {
  return temp - 0.55 * (1.0 - humidity / 100.0) * (temp - 14.5);
}

// ===================== FIREBASE: Write Sensor Data =====================
void writeSensorData(float temp, float hum, float thi, float nh3, bool fan, bool pump, bool online) {
  FirebaseJson json;
  json.set("temperature", temp);
  json.set("humidity", hum);
  json.set("thi", thi);
  json.set("ammonia", nh3);
  json.set("relay_fan", fan);
  json.set("relay_pump", pump);
  json.set("online", online);

  struct tm timeinfo;
  if (getLocalTime(&timeinfo)) {
    json.set("hour", timeinfo.tm_hour);
    json.set("minute", timeinfo.tm_min);
  } else {
    json.set("hour", 0);
    json.set("minute", 0);
  }

  json.set("device_id", "ESP32-01");

  if (Firebase.RTDB.setJSON(&fbdo, "/sensor_data", &json)) {
    Serial.println("[FB] sensor_data written OK");
  } else {
    Serial.printf("[FB] sensor_data FAILED: %s\n", fbdo.errorReason().c_str());
  }
}

// ===================== FIREBASE: Write History =====================
void writeHistory(float temp, float hum, float thi, float nh3, bool fan, bool pump) {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) {
    Serial.println("[FB] Skipped history write: NTP time not available");
    return;
  }

  char dateStr[11];
  snprintf(dateStr, sizeof(dateStr), "%04d-%02d-%02d",
           timeinfo.tm_year + 1900, timeinfo.tm_mon + 1, timeinfo.tm_mday);

  char timeStr[6];
  snprintf(timeStr, sizeof(timeStr), "%02d:%02d",
           timeinfo.tm_hour, timeinfo.tm_min);

  char path[64];
  snprintf(path, sizeof(path), "/history/%s/%s", dateStr, timeStr);

  FirebaseJson json;
  json.set("t", temp);
  json.set("h", hum);
  json.set("a", nh3);
  json.set("thi", thi);
  json.set("f", fan ? 1 : 0);
  json.set("p", pump ? 1 : 0);

  if (Firebase.RTDB.setJSON(&fbdo, path, &json)) {
    Serial.printf("[FB] history written: %s/%s\n", dateStr, timeStr);
  } else {
    Serial.printf("[FB] history FAILED: %s\n", fbdo.errorReason().c_str());
  }
}

// ===================== FIREBASE: Read Controls =====================
void readControls() {
  if (Firebase.RTDB.getBool(&fbdo, "/controls/fan")) {
    bool newFan = fbdo.boolData();
    if (newFan != fanState) {
      fanState = newFan;
      Serial.printf("[CTRL] Fan -> %s\n", fanState ? "ON" : "OFF");
    }
  }

  if (Firebase.RTDB.getBool(&fbdo, "/controls/pump")) {
    bool newPump = fbdo.boolData();
    if (newPump != pumpState) {
      pumpState = newPump;
      Serial.printf("[CTRL] Pump -> %s\n", pumpState ? "ON" : "OFF");
    }
  }

  if (Firebase.RTDB.getBool(&fbdo, "/controls/feed_now")) {
    bool feedCmd = fbdo.boolData();
    if (feedCmd) {
      Serial.println("[CTRL] Feed triggered!");
      startFeeding();
      Firebase.RTDB.setBool(&fbdo, "/controls/feed_now", false);
    }
  }

  executeControl(fanState, pumpState);
}

// ===================== ACTUATOR CONTROL =====================
void executeControl(bool fan, bool pump) {
  if (fan) {
    analogWrite(FAN_PWM_PIN, 255);
  } else {
    analogWrite(FAN_PWM_PIN, 0);
  }
  digitalWrite(PUMP_RELAY_PIN, pump ? HIGH : LOW);
}

// ===================== NON-BLOCKING FEEDER =====================
void startFeeding() {
  feedActive = true;
  feedStartTime = millis();
  digitalWrite(FEEDER_RELAY_PIN, HIGH);
}

void checkFeedStatus() {
  if (feedActive && (millis() - feedStartTime >= 2000)) {
    feedActive = false;
    digitalWrite(FEEDER_RELAY_PIN, LOW);
    Serial.println("[CTRL] Feeder OFF (2s completed)");
  }
}

// ===================== END =====================
