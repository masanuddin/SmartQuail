// [INDO] Dashboard Screen - FULL VERSION dengan Amonia
// lib/screens/dashboard_screen.dart

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
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  double temperature = 0.0;
  double humidity = 0.0;
  double thi = 0.0;
  int amonia = 0;
  bool relayFan = false;
  bool relayPump = false;
  bool autoMode = true;
  String systemStatus = 'normal';
  bool isOnline = false;
  DateTime lastUpdate = DateTime.now();

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
          amonia = (data['amonia'] ?? 0).toInt();
          relayFan = data['relay_fan'] ?? false;
          relayPump = data['relay_pump'] ?? false;
          autoMode = data['auto_mode'] ?? true;
          isOnline = data['online'] ?? false;
          lastUpdate = DateTime.now();
          
          // Determine status
          if (thi < 72) {
            systemStatus = 'normal';
          } else if (thi < 78) {
            systemStatus = 'warning';
          } else {
            systemStatus = 'danger';
          }
        });
        
        // Check amonia alert
        if (amonia > 50) {
          _showAmoniaAlert();
        }
      }
    });
  }

  void _showAmoniaAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('⚠️ BAHAYA! Amonia tinggi ($amonia ppm)\nSegera bersihkan kandang!'),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {},
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  StatusBanner(status: systemStatus, thi: thi),
                  const SizedBox(height: 16),
                  _buildKPIGrid(),
                  const SizedBox(height: 20),
                  _buildAmoniaCard(),
                  const SizedBox(height: 20),
                  _buildRelayStatus(),
                  const SizedBox(height: 20),
                  _buildTHISection(),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SmartQuail',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  autoMode ? 'Mode: AUTO' : 'Mode: MANUAL',
                  style: TextStyle(
                    fontSize: 12,
                    color: autoMode ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: isOnline ? Colors.green : Colors.red,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              amonia > 50 ? Icons.warning_rounded : Icons.cloud_rounded,
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gas Amonia (NH₃)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$amonia ppm - $statusText',
                  style: TextStyle(
                    fontSize: 16,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.power_settings_new, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Status Perangkat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRelayItem('Kipas', relayFan, Icons.air_rounded),
              ),
              const SizedBox(width: 12),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOn ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isOn ? Colors.green : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                isOn ? 'ON' : 'OFF',
                style: TextStyle(
                  fontSize: 16,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: Color(0xFF5856D6), size: 20),
              const SizedBox(width: 8),
              const Text(
                'THI Monitor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          THIGauge(value: thi),
        ],
      ),
    );
  }

  Widget _buildLastUpdate() {
    return Center(
      child: Text(
        'Update: ${lastUpdate.hour.toString().padLeft(2, '0')}:${lastUpdate.minute.toString().padLeft(2, '0')}:${lastUpdate.second.toString().padLeft(2, '0')}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
    );
  }
}