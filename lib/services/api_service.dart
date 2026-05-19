import 'package:firebase_database/firebase_database.dart';

/// ApiService - Sinkron dengan ESP32 SmartQuail v5.0
///
/// Path Firebase:
///   /sensor_data    ← ESP32 tulis, Flutter baca
///   /controls       ← Flutter tulis, ESP32 baca
///   /history        ← ESP32 tulis, Flutter baca
///
/// Untuk multi-kandang nanti:
///   /devices/{deviceId}/sensor_data
///   /devices/{deviceId}/controls
///   /devices/{deviceId}/history

class ApiService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Device ID aktif (untuk multi-kandang nanti)
  String _activeDeviceId = 'ESP32-01';

  // Apakah pakai mode multi-kandang
  final bool _useMultiCage = false;

  // ─── Helper: Path berdasarkan mode ───

  String get _sensorPath =>
      _useMultiCage ? 'devices/$_activeDeviceId/sensor_data' : 'sensor_data';

  String get _controlsPath =>
      _useMultiCage ? 'devices/$_activeDeviceId/controls' : 'controls';

  String get _historyPath =>
      _useMultiCage ? 'devices/$_activeDeviceId/history' : 'history';

  // ─── Setter untuk device aktif ───

  void setActiveDevice(String deviceId) {
    _activeDeviceId = deviceId;
  }

  String get activeDeviceId => _activeDeviceId;

  // ════════════════════════════════════════════
  //  SENSOR DATA (Baca dari ESP32)
  // ════════════════════════════════════════════

  /// Stream real-time sensor data
  Stream<DatabaseEvent> getSensorStream() {
    return _dbRef.child(_sensorPath).onValue;
  }

  /// Baca sensor data sekali
  Future<Map<String, dynamic>?> getSensorData() async {
    try {
      final snapshot = await _dbRef.child(_sensorPath).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      print('[ApiService] Error getting sensor data: $e');
    }
    return null;
  }

  /// Cek apakah ESP32 online
  Stream<DatabaseEvent> getOnlineStatus() {
    return _dbRef.child('$_sensorPath/online').onValue;
  }

  // ════════════════════════════════════════════
  //  KONTROL (Tulis ke Firebase → ESP32 baca)
  // ════════════════════════════════════════════

  /// Set kipas ON/OFF
  Future<void> setFan(bool value) async {
    try {
      await _dbRef.child('$_controlsPath/fan').set(value);
    } catch (e) {
      print('[ApiService] Error setting fan: $e');
      rethrow;
    }
  }

  /// Set pompa ON/OFF
  Future<void> setPump(bool value) async {
    try {
      await _dbRef.child('$_controlsPath/pump').set(value);
    } catch (e) {
      print('[ApiService] Error setting pump: $e');
      rethrow;
    }
  }

  /// Set auto mode ON/OFF
  Future<void> setAutoMode(bool value) async {
    try {
      await _dbRef.child('$_controlsPath/auto_mode').set(value);
    } catch (e) {
      print('[ApiService] Error setting auto mode: $e');
      rethrow;
    }
  }

  /// Trigger feed sekarang (one-shot, ESP32 akan reset ke false)
  Future<void> triggerFeedNow() async {
    try {
      await _dbRef.child('$_controlsPath/feed_now').set(true);
    } catch (e) {
      print('[ApiService] Error triggering feed: $e');
      rethrow;
    }
  }

  /// Baca status kontrol saat ini
  Future<Map<String, dynamic>?> getControlState() async {
    try {
      final snapshot = await _dbRef.child(_controlsPath).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      print('[ApiService] Error getting controls: $e');
    }
    return null;
  }

  /// Stream kontrol (untuk update UI real-time)
  Stream<DatabaseEvent> getControlStream() {
    return _dbRef.child(_controlsPath).onValue;
  }

  // ════════════════════════════════════════════
  //  HISTORY (Baca data riwayat)
  // ════════════════════════════════════════════

  /// Ambil history untuk tanggal tertentu
  /// [date] format: "2026-03-30"
  Future<Map<String, dynamic>?> getHistory(String date) async {
    try {
      final snapshot = await _dbRef.child('$_historyPath/$date').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      print('[ApiService] Error getting history: $e');
    }
    return null;
  }

  /// Ambil daftar tanggal yang ada history-nya
  Future<List<String>> getAvailableDates() async {
    try {
      final snapshot = await _dbRef.child(_historyPath).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final dates = data.keys.toList();
        dates.sort((a, b) => b.compareTo(a)); // Terbaru dulu
        return dates;
      }
    } catch (e) {
      print('[ApiService] Error getting dates: $e');
    }
    return [];
  }

  // ════════════════════════════════════════════
  //  HELPER: Parse sensor data dari snapshot
  // ════════════════════════════════════════════

  /// Parse snapshot menjadi SensorData object
  static SensorData? parseSensorData(DataSnapshot snapshot) {
    if (!snapshot.exists) return null;

    try {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return SensorData(
        temperature: (data['temperature'] ?? 0).toDouble(),
        humidity: (data['humidity'] ?? 0).toDouble(),
        ammonia: (data['ammonia'] ?? 0).toDouble(),
        thi: (data['thi'] ?? 0).toDouble(),
        relayFan: data['relay_fan'] ?? false,
        relayPump: data['relay_pump'] ?? false,
        autoMode: data['auto_mode'] ?? false,
        online: data['online'] ?? false,
        hour: data['hour'] ?? 0,
        minute: data['minute'] ?? 0,
        deviceId: data['device_id'] ?? 'unknown',
      );
    } catch (e) {
      print('[ApiService] Error parsing sensor data: $e');
      return null;
    }
  }
}

// ════════════════════════════════════════════
//  MODEL: SensorData
// ════════════════════════════════════════════

class SensorData {
  final double temperature;
  final double humidity;
  final double ammonia;
  final double thi;
  final bool relayFan;
  final bool relayPump;
  final bool autoMode;
  final bool online;
  final int hour;
  final int minute;
  final String deviceId;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.ammonia,
    required this.thi,
    required this.relayFan,
    required this.relayPump,
    required this.autoMode,
    required this.online,
    required this.hour,
    required this.minute,
    required this.deviceId,
  });

  /// Status THI
  String get thiStatus {
    if (thi < 72) return 'Normal';
    if (thi < 78) return 'Warning';
    return 'Danger';
  }

  /// Warna status THI (untuk UI)
  String get thiColorHex {
    if (thi < 72) return '#4CAF50';  // Green
    if (thi < 78) return '#FF9800';  // Orange
    return '#F44336';                 // Red
  }

  /// Format waktu
  String get timeString =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}