// History Service - Membaca data riwayat dari Firebase
// ✅ Path: /history/{date}/{time}
// lib/services/history_service.dart

import 'package:firebase_database/firebase_database.dart';

class HistoryData {
  final String time;
  final double temperature;
  final double humidity;
  final double ammonia;
  final double thi;
  final bool fan;
  final bool pump;

  HistoryData({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.ammonia,
    required this.thi,
    required this.fan,
    required this.pump,
  });

  // ✅ Validasi: data dianggap valid jika sensor memberikan nilai masuk akal
  bool get isValid =>
      temperature > 5.0 &&
      temperature < 60.0 &&
      humidity > 5.0 &&
      humidity <= 100.0 &&
      thi > 40.0 &&
      thi < 110.0;
}

class HistoryStats {
  final double avgTemp;
  final double minTemp;
  final double maxTemp;
  final double avgHumidity;
  final double minHumidity;
  final double maxHumidity;
  final double avgThi;
  final int coolingEvents;

  HistoryStats({
    required this.avgTemp,
    required this.minTemp,
    required this.maxTemp,
    required this.avgHumidity,
    required this.minHumidity,
    required this.maxHumidity,
    required this.avgThi,
    required this.coolingEvents,
  });
}

class HistoryService {
  static final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  static const String _historyPath = 'history';

  // ════════════════════════════════════════════
  //  Ambil data berdasarkan periode
  // ════════════════════════════════════════════

  static Future<List<HistoryData>> getLastHour() async {
    final now = DateTime.now();
    final data = await _getDateData(_formatDate(now));
    if (data.length > 12) return data.sublist(data.length - 12);
    return data;
  }

  static Future<List<HistoryData>> getLast24Hours() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    List<HistoryData> allData = [];
    allData.addAll(await _getDateData(_formatDate(now)));
    if (now.hour < 24) {
      final yesterdayData = await _getDateData(_formatDate(yesterday));
      allData.insertAll(0, yesterdayData);
    }

    if (allData.length > 288) {
      allData = allData.sublist(allData.length - 288);
    }
    return allData;
  }

  static Future<List<HistoryData>> getLast7Days() async {
    List<HistoryData> allData = [];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      allData.addAll(await _getDateData(_formatDate(date)));
    }
    return allData;
  }

  static Future<List<HistoryData>> getLast30Days() async {
    List<HistoryData> allData = [];
    final now = DateTime.now();
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayData = await _getDateData(_formatDate(date));
      for (int j = 0; j < dayData.length; j += 6) {
        allData.add(dayData[j]);
      }
    }
    return allData;
  }

  // ════════════════════════════════════════════
  //  Helper: Ambil & FILTER data per tanggal
  // ════════════════════════════════════════════

  static Future<List<HistoryData>> _getDateData(String dateStr) async {
    try {
      final snapshot = await _dbRef.child('$_historyPath/$dateStr').get();
      if (!snapshot.exists) return [];

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final List<HistoryData> result = [];
      final sortedKeys = data.keys.toList()..sort();

      for (final timeKey in sortedKeys) {
        final entry = data[timeKey];
        if (entry is Map) {
          final point = HistoryData(
            time: timeKey,
            temperature: (entry['t'] ?? 0).toDouble(),
            humidity: (entry['h'] ?? 0).toDouble(),
            ammonia: (entry['a'] ?? 0).toDouble(),
            thi: (entry['thi'] ?? 0).toDouble(),
            fan: (entry['f'] ?? 0) == 1,
            pump: (entry['p'] ?? 0) == 1,
          );

          // ✅ Filter data invalid (sensor belum ready / nilai 0)
          if (point.isValid) {
            result.add(point);
          } else {
            print('[HistoryService] Skip invalid: $dateStr/$timeKey '
                't=${point.temperature}, h=${point.humidity}, thi=${point.thi}');
          }
        }
      }
      return result;
    } catch (e) {
      print('[HistoryService] Error loading $dateStr: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════
  //  Statistik (hanya dari data valid)
  // ════════════════════════════════════════════

  static HistoryStats calculateStats(List<HistoryData> data) {
    // ✅ Double-filter: pastikan tidak ada data invalid lolos ke statistik
    final validData = data.where((d) => d.isValid).toList();

    if (validData.isEmpty) {
      return HistoryStats(
        avgTemp: 0, minTemp: 0, maxTemp: 0,
        avgHumidity: 0, minHumidity: 0, maxHumidity: 0,
        avgThi: 0, coolingEvents: 0,
      );
    }

    double sumTemp = 0, sumHum = 0, sumThi = 0;
    double minTemp = double.infinity, maxTemp = double.negativeInfinity;
    double minHum = double.infinity, maxHum = double.negativeInfinity;
    int coolingEvents = 0;
    bool wasCooling = false;

    for (final d in validData) {
      sumTemp += d.temperature;
      sumHum += d.humidity;
      sumThi += d.thi;

      if (d.temperature < minTemp) minTemp = d.temperature;
      if (d.temperature > maxTemp) maxTemp = d.temperature;
      if (d.humidity < minHum) minHum = d.humidity;
      if (d.humidity > maxHum) maxHum = d.humidity;

      if ((d.fan || d.pump) && !wasCooling) coolingEvents++;
      wasCooling = d.fan || d.pump;
    }

    final n = validData.length;
    return HistoryStats(
      avgTemp: sumTemp / n,
      minTemp: minTemp == double.infinity ? 0 : minTemp,
      maxTemp: maxTemp == double.negativeInfinity ? 0 : maxTemp,
      avgHumidity: sumHum / n,
      minHumidity: minHum == double.infinity ? 0 : minHum,
      maxHumidity: maxHum == double.negativeInfinity ? 0 : maxHum,
      avgThi: sumThi / n,
      coolingEvents: coolingEvents,
    );
  }

  // ════════════════════════════════════════════
  //  Helper: Format tanggal
  // ════════════════════════════════════════════

  static String _formatDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}