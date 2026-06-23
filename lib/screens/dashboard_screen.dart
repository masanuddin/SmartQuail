// [INDO] Dashboard Screen - FIXED VERSION
// Path Firebase disinkronkan dengan ESP32 SmartQuail v5.0
// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/kpi_card.dart';
import '../widgets/thi_gauge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  double temperature = 0.0;
  double humidity = 0.0;
  double thi = 0.0;
  int amonia = 0;
  bool relayFan = false;
  bool relayPump = false;
  String systemStatus = 'normal';
  bool isOnline = false;
  DateTime lastUpdate = DateTime.now();

  StreamSubscription<DatabaseEvent>? _dataSubscription;
  bool _alertShown = false;

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

  void _listenToFirebase() {
    // ════════════════════════════════════════════
    // ✅ FIX: Path disinkronkan dengan ESP32
    // ESP32 menulis ke /sensor_data
    // ════════════════════════════════════════════
    _dataSubscription = _database
        .child('sensor_data')  // ✅ FIXED - sebelumnya 'smartquail/devices/esp32-01'
        .onValue
        .listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      
      if (data != null && mounted) {
        setState(() {
          temperature = (data['temperature'] ?? 0).toDouble();
          humidity = (data['humidity'] ?? 0).toDouble();
          thi = (data['thi'] ?? 0).toDouble();
          amonia = (data['ammonia'] ?? data['amonia'] ?? 0).toInt(); // support kedua key
          relayFan = data['relay_fan'] ?? false;
          relayPump = data['relay_pump'] ?? false;
          isOnline = data['online'] ?? false;
          lastUpdate = DateTime.now();
          
          if (thi < 72) {
            systemStatus = 'normal';
          } else if (thi < 78) {
            systemStatus = 'warning';
          } else {
            systemStatus = 'danger';
          }
        });
        
        // Alert amonia hanya sekali
        if (amonia > 50 && !_alertShown) {
          _alertShown = true;
          _showAmoniaAlert();
          Future.delayed(const Duration(seconds: 30), () {
            _alertShown = false;
          });
        }
      }
    });
  }

  void _showAmoniaAlert() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('⚠️ BAHAYA! Amonia tinggi ($amonia ppm)\nSegera bersihkan kandang!'),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),
                        _buildStatusBanner(),
                        const SizedBox(height: 16),
                        _buildKPIGrid(),
                        const SizedBox(height: 16),
                        _buildAmoniaCard(),
                        const SizedBox(height: 16),
                        _buildRelayStatus(),
                        const SizedBox(height: 16),
                        _buildTHISection(),
                        const SizedBox(height: 12),
                        _buildLastUpdate(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/images/smartquail.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SmartQuail',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: isOnline ? Colors.green : Colors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    Color bannerColor;
    String title;
    String subtitle;

    if (systemStatus == 'danger') {
      bannerColor = const Color(0xFFFF3B30);
      title = 'Bahaya - Pendinginan Aktif';
      subtitle = 'THI sangat tinggi, semua sistem cooling aktif';
    } else if (systemStatus == 'warning') {
      bannerColor = const Color(0xFFFF9500);
      title = 'Perhatian - Kipas Aktif';
      subtitle = 'THI memasuki zona warning, kipas dinyalakan';
    } else {
      bannerColor = const Color(0xFF34C759);
      title = 'Normal - Sistem Standby';
      subtitle = 'Kondisi kandang dalam keadaan optimal';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bannerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bannerColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              systemStatus == 'danger' 
                  ? Icons.warning_rounded 
                  : systemStatus == 'warning'
                      ? Icons.info_rounded
                      : Icons.check_circle_rounded,
              color: bannerColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: bannerColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bannerColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'THI ${thi.toStringAsFixed(1)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
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
          icon: Icons.cloud_rounded,
          label: 'Amonia',
          value: '$amonia ppm',
          status: amonia > 50 ? 'danger' : (amonia > 25 ? 'warning' : 'normal'),
          color: const Color(0xFF34C759),
        ),
      ],
    );
  }

  Widget _buildAmoniaCard() {
    Color statusColor = amonia > 50 ? Colors.red : (amonia > 25 ? Colors.orange : Colors.green);
    String statusText = amonia > 50 ? 'BAHAYA! Bersihkan kandang!' : (amonia > 25 ? 'Perhatian' : 'Normal');
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              amonia > 50 ? Icons.warning_rounded : Icons.cloud_rounded,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gas Amonia (NH₃)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$amonia ppm - $statusText',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelayStatus() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.power_settings_new, color: Colors.blue, size: 18),
              SizedBox(width: 8),
              Text(
                'Status Perangkat',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRelayItem('Kipas', relayFan, Icons.air_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildRelayItem('Pompa', relayPump, Icons.water_drop_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRelayItem(String label, bool isOn, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isOn ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isOn ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                isOn ? 'ON' : 'OFF',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isOn ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTHISection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.speed, color: Color(0xFF5856D6), size: 18),
              SizedBox(width: 8),
              Text(
                'THI Monitor',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: THIGauge(value: thi),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdate() {
    return Center(
      child: Text(
        'Update: ${lastUpdate.hour.toString().padLeft(2, '0')}:${lastUpdate.minute.toString().padLeft(2, '0')}:${lastUpdate.second.toString().padLeft(2, '0')}',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[500],
        ),
      ),
    );
  }
}