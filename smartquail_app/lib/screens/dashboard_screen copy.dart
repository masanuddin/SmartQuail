// [INDO] Dashboard Screen - FIREBASE VERSION
// Mengambil data real-time dari Firebase Realtime Database

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/kpi_card.dart';
import '../widgets/thi_gauge.dart';
import '../widgets/status_banner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // [INDO] Firebase Database Reference
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  // [INDO] Data sensor
  double temperature = 0.0;
  double humidity = 0.0;
  double thi = 0.0;
  double amonia = 0.0;
  String relayStatus = 'OFF';
  String systemStatus = 'normal';
  bool isOnline = false;
  DateTime lastUpdate = DateTime.now();

  // [INDO] Stream subscription untuk realtime updates
  StreamSubscription<DatabaseEvent>? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _listenToFirebase();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  // [INDO] Listen ke Firebase Realtime Database
  void _listenToFirebase() {
    _dataSubscription = _database
        .child('smartquail/devices/esp32-01')
        .onValue
        .listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      
      if (data != null) {
        setState(() {
          temperature = (data['temperature'] ?? 0).toDouble();
          humidity = (data['humidity'] ?? 0).toDouble();
          thi = (data['thi'] ?? 0).toDouble();
          amonia = (data['amonia'] ?? 0).toDouble();
          relayStatus = data['relay_status'] ?? 'OFF';
          isOnline = data['online'] ?? false;
          
          // [INDO] Update timestamp
          if (data['timestamp'] != null) {
            lastUpdate = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
          } else {
            lastUpdate = DateTime.now();
          }
          
          // [INDO] Tentukan status berdasarkan THI
          if (thi < 72) {
            systemStatus = 'normal';
          } else if (thi < 78) {
            systemStatus = 'warning';
          } else {
            systemStatus = 'danger';
          }
        });
      }
    }, onError: (error) {
      print('Firebase Error: $error');
      setState(() {
        isOnline = false;
      });
    });
  }

  // [INDO] Manual refresh data
  Future<void> _refreshData() async {
    final snapshot = await _database.child('smartquail/devices/esp32-01').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        temperature = (data['temperature'] ?? 0).toDouble();
        humidity = (data['humidity'] ?? 0).toDouble();
        thi = (data['thi'] ?? 0).toDouble();
        amonia = (data['amonia'] ?? 0).toDouble();
        relayStatus = data['relay_status'] ?? 'OFF';
        isOnline = data['online'] ?? false;
        lastUpdate = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildDeviceSelector(),
                  const SizedBox(height: 16),
                  StatusBanner(
                    status: systemStatus,
                    thi: thi,
                  ),
                  const SizedBox(height: 20),
                  _buildKPIGrid(),
                  const SizedBox(height: 24),
                  _buildTHISection(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 16),
                  _buildLastUpdate(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🐦', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SmartQuail',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    Text(
                      'Monitoring Kandang Cerdas',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        // Status Online/Offline
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isOnline ? const Color(0xFF34C759).withOpacity(0.1) : const Color(0xFFFF3B30).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: isOnline ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.memory,
            color: isOnline ? const Color(0xFF007AFF) : const Color(0xFF8E8E93),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kandang 1 - ESP32-01',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                Text(
                  isOnline ? 'Connected to Firebase' : 'Disconnected',
                  style: TextStyle(
                    fontSize: 11,
                    color: isOnline ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8E8E93)),
        ],
      ),
    );
  }

  Widget _buildKPIGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        KPICard(
          icon: Icons.thermostat_rounded,
          label: 'Suhu',
          value: '${temperature.toStringAsFixed(1)}°C',
          status: temperature > 30 ? 'danger' : (temperature > 26 ? 'warning' : 'normal'),
          color: const Color(0xFFFF9500),
        ),
        KPICard(
          icon: Icons.water_drop_rounded,
          label: 'Kelembaban',
          value: '${humidity.toStringAsFixed(0)}%',
          status: humidity > 80 ? 'warning' : 'normal',
          color: const Color(0xFF007AFF),
        ),
        KPICard(
          icon: Icons.speed_rounded,
          label: 'Indeks THI',
          value: thi.toStringAsFixed(1),
          status: systemStatus,
          color: const Color(0xFF5856D6),
        ),
        KPICard(
          icon: Icons.air_rounded,
          label: 'Sistem',
          value: relayStatus == 'ON' ? 'Aktif' : (relayStatus == 'FAN' ? 'Kipas' : 'Standby'),
          status: relayStatus == 'ON' ? 'active' : 'normal',
          color: const Color(0xFF34C759),
          showPulse: relayStatus == 'ON',
        ),
      ],
    );
  }

  Widget _buildTHISection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.speed, color: Color(0xFF5856D6), size: 20),
              SizedBox(width: 8),
              Text(
                'THI Monitor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          THIGauge(value: thi),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Normal', '<72', const Color(0xFF34C759)),
              _buildLegendItem('Warning', '72-78', const Color(0xFFFF9500)),
              _buildLegendItem('Danger', '>78', const Color(0xFFFF3B30)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String range, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
            ),
            Text(
              range,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.show_chart_rounded,
            label: 'Lihat Grafik',
            color: const Color(0xFF007AFF),
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.tune_rounded,
            label: 'Kontrol Manual',
            color: const Color(0xFF5856D6),
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdate() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOnline ? Icons.cloud_done : Icons.cloud_off,
            size: 14,
            color: const Color(0xFF8E8E93),
          ),
          const SizedBox(width: 6),
          Text(
            'Update: ${lastUpdate.hour.toString().padLeft(2, '0')}:${lastUpdate.minute.toString().padLeft(2, '0')}:${lastUpdate.second.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }
}
