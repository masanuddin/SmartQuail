import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';

class ApiService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  String _activeDeviceId = 'ESP32-01';
  final bool _useMultiCage = false;

  String get _sensorPath =>
      _useMultiCage ? 'devices/$_activeDeviceId/sensor_data' : 'sensor_data';

  String get _controlsPath =>
      _useMultiCage ? 'devices/$_activeDeviceId/controls' : 'controls';

  String get _historyPath =>
      _useMultiCage ? 'devices/$_activeDeviceId/history' : 'history';

  void setActiveDevice(String deviceId) {
    _activeDeviceId = deviceId;
  }

  String get activeDeviceId => _activeDeviceId;

  Stream<DatabaseEvent> getSensorStream() {
    return _dbRef.child(_sensorPath).onValue;
  }

  Future<SensorData?> getSensorData() async {
    try {
      final snapshot = await _dbRef.child(_sensorPath).get();
      if (snapshot.exists) {
        final raw = snapshot.value;
        if (raw is Map) {
          return SensorData.fromMap(Map<String, dynamic>.from(raw));
        }
      }
    } catch (e) {
      print('[ApiService] Error getting sensor data: $e');
    }
    return null;
  }

  Stream<DatabaseEvent> getOnlineStatus() {
    return _dbRef.child('$_sensorPath/online').onValue;
  }

  Future<void> setFan(bool value) async {
    try {
      await _dbRef.child('$_controlsPath/fan').set(value);
    } catch (e) {
      print('[ApiService] Error setting fan: $e');
      rethrow;
    }
  }

  Future<void> setPump(bool value) async {
    try {
      await _dbRef.child('$_controlsPath/pump').set(value);
    } catch (e) {
      print('[ApiService] Error setting pump: $e');
      rethrow;
    }
  }

  Future<void> triggerFeedNow() async {
    try {
      await _dbRef.child('$_controlsPath/feed_now').set(true);
    } catch (e) {
      print('[ApiService] Error triggering feed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getControlState() async {
    try {
      final snapshot = await _dbRef.child(_controlsPath).get();
      if (snapshot.exists) {
        final raw = snapshot.value;
        if (raw is Map) {
          return Map<String, dynamic>.from(raw);
        }
      }
    } catch (e) {
      print('[ApiService] Error getting controls: $e');
    }
    return null;
  }

  Stream<DatabaseEvent> getControlStream() {
    return _dbRef.child(_controlsPath).onValue;
  }

  Future<Map<String, dynamic>?> getHistory(String date) async {
    try {
      final snapshot = await _dbRef.child('$_historyPath/$date').get();
      if (snapshot.exists) {
        final raw = snapshot.value;
        if (raw is Map) {
          return Map<String, dynamic>.from(raw);
        }
      }
    } catch (e) {
      print('[ApiService] Error getting history: $e');
    }
    return null;
  }

  Future<List<String>> getAvailableDates() async {
    try {
      final snapshot = await _dbRef.child(_historyPath).get();
      if (snapshot.exists) {
        final raw = snapshot.value;
        if (raw is Map) {
          final data = Map<String, dynamic>.from(raw);
          final dates = data.keys.toList();
          dates.sort((a, b) => b.compareTo(a));
          return dates;
        }
      }
    } catch (e) {
      print('[ApiService] Error getting dates: $e');
    }
    return [];
  }

  static SensorData? parseFromEvent(DatabaseEvent event) {
    if (!event.snapshot.exists) return null;
    try {
      final raw = event.snapshot.value;
      if (raw is Map) {
        return SensorData.fromMap(Map<String, dynamic>.from(raw));
      }
    } catch (e) {
      print('[ApiService] Error parsing sensor data: $e');
    }
    return null;
  }
}
