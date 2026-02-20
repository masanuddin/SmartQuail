// [INDO] Dashboard Screen - Halaman utama monitoring
// Menampilkan suhu, kelembaban, THI, dan status sistem

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../widgets/kpi_card.dart';
import '../widgets/thi_gauge.dart';
import '../widgets/status_banner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // [INDO] Data sensor (nanti diganti dengan data real dari Supabase)
  double temperature = 28.5;
  double humidity = 68.0;
  double thi = 75.2;
  String relayStatus = 'OFF';
  String systemStatus = 'normal'; // normal, warning, danger
  bool isOnline = true;
  DateTime lastUpdate = DateTime.now();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // [INDO] Simulasi update data setiap 2 detik (ganti dengan Supabase realtime nanti)
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _simulateDataUpdate();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // [INDO] Simulasi perubahan data (HAPUS ini nanti, ganti Supabase)
  void _simulateDataUpdate() {
    setState(() {
      // Random fluctuation untuk demo
      temperature = 26 + Random().nextDouble() * 6; // 26-32°C
      humidity = 60 + Random().nextDouble() * 25; // 60-85%
      
      // Hitung THI
      thi = 0.8 * temperature + (humidity / 100) * (temperature - 14.4) + 46.4;
      
      // Tentukan status berdasarkan THI
      if (thi < 72) {
        systemStatus = 'normal';
        relayStatus = 'OFF';
      } else if (thi < 78) {
        systemStatus = 'warning';
        relayStatus = 'FAN';
      } else {
        systemStatus = 'danger';
        relayStatus = 'ON';
      }
      
      lastUpdate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // [INDO] Header dengan logo dan status koneksi
                _buildHeader(),
                const SizedBox(height: 20),

                // [INDO] Device selector
                _buildDeviceSelector(),
                const SizedBox(height: 16),

                // [INDO] Status Banner
                StatusBanner(
                  status: systemStatus,
                  thi: thi,
                ),
                const SizedBox(height: 20),

                // [INDO] KPI Cards Grid (2x2)
                _buildKPIGrid(),
                const SizedBox(height: 24),

                // [INDO] THI Gauge
                _buildTHISection(),
                const SizedBox(height: 24),

                // [INDO] Quick Actions
                _buildQuickActions(),
                const SizedBox(height: 16),

                // [INDO] Last Update Info
                _buildLastUpdate(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // [INDO] Header dengan judul dan status online
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Logo
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

  // [INDO] Dropdown pemilih device/kandang
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
          const Icon(Icons.memory, color: Color(0xFF007AFF), size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kandang 1 - ESP32-01',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                Text(
                  'Device ID: esp32-smartquail-01',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8E8E93),
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

  // [INDO] Grid 2x2 untuk KPI Cards
  Widget _buildKPIGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
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

  // [INDO] Section THI Gauge
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
          // Legend
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

  // [INDO] Quick Action Buttons
  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.show_chart_rounded,
            label: 'Lihat Grafik',
            color: const Color(0xFF007AFF),
            onTap: () {
              // Navigate ke History tab
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.tune_rounded,
            label: 'Kontrol Manual',
            color: const Color(0xFF5856D6),
            onTap: () {
              // Navigate ke Control tab
            },
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

  // [INDO] Info waktu update terakhir
  Widget _buildLastUpdate() {
    return Center(
      child: Text(
        'Update terakhir: ${lastUpdate.hour.toString().padLeft(2, '0')}:${lastUpdate.minute.toString().padLeft(2, '0')}:${lastUpdate.second.toString().padLeft(2, '0')}',
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF8E8E93),
        ),
      ),
    );
  }
}
