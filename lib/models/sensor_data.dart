class SensorData {
  final double temperature;
  final double humidity;
  final double ammonia;
  final double thi;
  final bool relayFan;
  final bool relayPump;
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
    required this.online,
    required this.hour,
    required this.minute,
    required this.deviceId,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> data) {
    return SensorData(
      temperature: _safeDouble(data['temperature']),
      humidity: _safeDouble(data['humidity']),
      ammonia: _safeDouble(data['ammonia'] ?? data['amonia']),
      thi: _safeDouble(data['thi']),
      relayFan: data['relay_fan'] == true || data['relay_fan'] == 1,
      relayPump: data['relay_pump'] == true || data['relay_pump'] == 1,
      online: data['online'] == true || data['online'] == 1,
      hour: _safeInt(data['hour']),
      minute: _safeInt(data['minute']),
      deviceId: data['device_id']?.toString() ?? 'unknown',
    );
  }

  static double _safeDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _safeInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  String get thiStatus {
    if (thi < 72) return 'normal';
    if (thi < 78) return 'warning';
    return 'danger';
  }

  String get timeString =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
