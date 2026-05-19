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
  
  // ✅ Path yang sama dengan ESP32
  static const String _historyPath = 'history';

  // ════════════════════════════════════════════
  //  Ambil data berdasarkan periode
  // ════════════════════════════════════════════

  /// Data 1 jam terakhir
  static Future<List<HistoryData>> getLastHour() async {
    final now = DateTime.now();
    final dateStr = _formatDate(now);
    final data = await _getDateData(dateStr);
    
    // Filter hanya 1 jam terakhir (12 data points @ 5 menit)
    if (data.length > 12) {
      return data.sublist(data.length - 12);
    }
    return data;
  }

  /// Data 24 jam terakhir
  static Future<List<HistoryData>> getLast24Hours() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    
    List<HistoryData> allData = [];
    
    // Ambil data hari ini
    allData.addAll(await _getDateData(_formatDate(now)));
    
    // Ambil data kemarin (jika perlu)
    if (now.hour < 24) {
      final yesterdayData = await _getDateData(_formatDate(yesterday));
      allData.insertAll(0, yesterdayData);
    }
    
    // Batasi 288 data points (24 jam * 12 per jam)
    if (allData.length > 288) {
      allData = allData.sublist(allData.length - 288);
    }
    
    return allData;
  }

  /// Data 7 hari terakhir
  static Future<List<HistoryData>> getLast7Days() async {
    List<HistoryData> allData = [];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayData = await _getDateData(_formatDate(date));
      allData.addAll(dayData);
    }
    
    return allData;
  }

  /// Data 30 hari terakhir
  static Future<List<HistoryData>> getLast30Days() async {
    List<HistoryData> allData = [];
    final now = DateTime.now();
    
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayData = await _getDateData(_formatDate(date));
      // Ambil sample (setiap 6 data = tiap 30 menit) untuk 30 hari
      for (int j = 0; j < dayData.length; j += 6) {
        allData.add(dayData[j]);
      }
    }
    
    return allData;
  }

  // ════════════════════════════════════════════
  //  Helper: Ambil data per tanggal
  // ════════════════════════════════════════════

  static Future<List<HistoryData>> _getDateData(String dateStr) async {
    try {
      final snapshot = await _dbRef.child('$_historyPath/$dateStr').get();
      
      if (!snapshot.exists) return [];
      
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final List<HistoryData> result = [];
      
      // Sort by time key (e.g., "0730", "0735", "0800")
      final sortedKeys = data.keys.toList()..sort();
      
      for (final timeKey in sortedKeys) {
        final entry = data[timeKey];
        if (entry is Map) {
          result.add(HistoryData(
            time: timeKey,
            temperature: (entry['t'] ?? 0).toDouble(),
            humidity: (entry['h'] ?? 0).toDouble(),
            ammonia: (entry['a'] ?? 0).toDouble(),
            thi: (entry['thi'] ?? 0).toDouble(),
            fan: (entry['f'] ?? 0) == 1,
            pump: (entry['p'] ?? 0) == 1,
          ));
        }
      }
      
      return result;
    } catch (e) {
      print('[HistoryService] Error loading $dateStr: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════
  //  Statistik
  // ════════════════════════════════════════════

  static HistoryStats calculateStats(List<HistoryData> data) {
    if (data.isEmpty) {
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

    for (final d in data) {
      sumTemp += d.temperature;
      sumHum += d.humidity;
      sumThi += d.thi;

      if (d.temperature < minTemp) minTemp = d.temperature;
      if (d.temperature > maxTemp) maxTemp = d.temperature;
      if (d.humidity < minHum) minHum = d.humidity;
      if (d.humidity > maxHum) maxHum = d.humidity;

      // Count cooling events (fan atau pump nyala)
      if ((d.fan || d.pump) && !wasCooling) {
        coolingEvents++;
      }
      wasCooling = d.fan || d.pump;
    }

    final n = data.length;
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