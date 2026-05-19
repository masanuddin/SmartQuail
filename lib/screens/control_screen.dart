// [INDO] Control Screen - FIXED VERSION
// ✅ FIX: Path Firebase disinkronkan dengan ESP32
//   - Baca sensor dari /sensor_data (bukan /smartquail/devices/esp32-01)
//   - Tulis kontrol ke /controls (bukan /smartquail/controls)
// lib/screens/control_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  bool isAutoMode = true;
  bool isFanOn = false;
  bool isPumpOn = false;

  double temperature = 0;
  double humidity = 0;
  double thi = 0;
  int amonia = 0;
  bool isOnline = false;

  StreamSubscription<DatabaseEvent>? _sensorSubscription;
  StreamSubscription<DatabaseEvent>? _controlSubscription;

  @override
  void initState() {
    super.initState();
    _listenToSensorData();
    _listenToControls();
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _controlSubscription?.cancel();
    super.dispose();
  }

  // ════════════════════════════════════════════
  // ✅ BACA sensor data dari /sensor_data
  // ════════════════════════════════════════════
  void _listenToSensorData() {
    _sensorSubscription = _database
        .child('sensor_data')  // ✅ FIXED
        .onValue
        .listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null && mounted) {
        setState(() {
          temperature = (data['temperature'] ?? 0).toDouble();
          humidity = (data['humidity'] ?? 0).toDouble();
          thi = (data['thi'] ?? 0).toDouble();
          amonia = (data['ammonia'] ?? data['amonia'] ?? 0).toInt();
          isOnline = data['online'] ?? false;
          // Baca status relay dari sensor_data (ESP32 yang report)
          isFanOn = data['relay_fan'] ?? false;
          isPumpOn = data['relay_pump'] ?? false;
          isAutoMode = data['auto_mode'] ?? true;
        });
      }
    });
  }

  // ════════════════════════════════════════════
  // ✅ LISTEN kontrol dari /controls (sinkron dengan ESP32)
  // ════════════════════════════════════════════
  void _listenToControls() {
    _controlSubscription = _database
        .child('controls')  // ✅ FIXED
        .onValue
        .listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null && mounted) {
        setState(() {
          // Update dari controls (yang Flutter tulis, ESP32 baca)
          isAutoMode = data['auto_mode'] ?? isAutoMode;
          isFanOn = data['fan'] ?? isFanOn;
          isPumpOn = data['pump'] ?? isPumpOn;
        });
      }
    });
  }

  // ════════════════════════════════════════════
  // ✅ TULIS kontrol ke /controls (ESP32 akan baca)
  // ════════════════════════════════════════════
  void _updateControl(String key, dynamic value) {
    _database.child('controls/$key').set(value);  // ✅ FIXED
  }

  void _triggerFeeding() {
    _database.child('controls/feed_now').set(true);  // ✅ FIXED
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🍽️ Feeding triggered!'),
        backgroundColor: Color(0xFF34C759),
        duration: Duration(seconds: 2),
      ),
    );
    // ESP32 akan reset feed_now ke false setelah selesai
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
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
                      const SizedBox(height: 12),
                      _buildConnectionStatus(),
                      const SizedBox(height: 12),
                      if (!isAutoMode) _buildWarningBanner(),
                      if (!isAutoMode) const SizedBox(height: 12),
                      _buildAutoModeCard(),
                      const SizedBox(height: 16),
                      _buildSensorMonitor(),
                      const SizedBox(height: 16),
                      _buildControlSection(),
                      const SizedBox(height: 16),
                      _buildFeederSection(),
                      const SizedBox(height: 16),
                      _buildPresetsSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.tune_rounded, color: Color(0xFF5856D6), size: 26),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kontrol Manual',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            Text(
              'Atur kipas dan pompa',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline 
            ? const Color(0xFF34C759).withOpacity(0.1)
            : const Color(0xFFFF3B30).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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
            isOnline ? 'ESP32 Online' : 'ESP32 Offline',
            style: TextStyle(
              color: isOnline ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9500).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF9500).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9500), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mode Manual Aktif',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF9500),
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Kontrol otomatis dinonaktifkan',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoModeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isAutoMode 
                      ? const Color(0xFF34C759).withOpacity(0.1)
                      : const Color(0xFFFF9500).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isAutoMode ? Icons.autorenew_rounded : Icons.pan_tool_rounded,
                  color: isAutoMode ? const Color(0xFF34C759) : const Color(0xFFFF9500),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mode Otomatis',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isAutoMode ? 'Kontrol berdasarkan THI' : 'Kontrol manual aktif',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch.adaptive(
            value: isAutoMode,
            activeColor: const Color(0xFF34C759),
            onChanged: (value) {
              setState(() => isAutoMode = value);
              _updateControl('auto_mode', value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSensorMonitor() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sensors_rounded, color: Color(0xFF007AFF), size: 18),
              SizedBox(width: 8),
              Text(
                'Sensor Monitor',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _sensorChip('🌡️ ${temperature.toStringAsFixed(1)}°C'),
              const SizedBox(width: 8),
              _sensorChip('💧 ${humidity.toStringAsFixed(0)}%'),
              const SizedBox(width: 8),
              _sensorChip('📊 THI ${thi.toStringAsFixed(1)}'),
              const SizedBox(width: 8),
              _sensorChip('☁️ $amonia ppm'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sensorChip(String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildControlSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.power_settings_new_rounded, color: Color(0xFF34C759), size: 18),
              SizedBox(width: 8),
              Text(
                'Kontrol Perangkat',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildControlTile(
            label: 'Kipas Utama',
            subtitle: 'Sirkulasi udara kandang',
            icon: Icons.air_rounded,
            color: const Color(0xFF34C759),
            isOn: isFanOn,
            enabled: !isAutoMode,
            onChanged: (value) {
              setState(() => isFanOn = value);
              _updateControl('fan', value);
            },
          ),
          const SizedBox(height: 10),
          _buildControlTile(
            label: 'Pompa Air / Misting',
            subtitle: 'Semprotkan kabut',
            icon: Icons.water_drop_rounded,
            color: const Color(0xFF007AFF),
            isOn: isPumpOn,
            enabled: !isAutoMode,
            onChanged: (value) {
              setState(() => isPumpOn = value);
              _updateControl('pump', value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isOn,
    required bool enabled,
    required Function(bool) onChanged,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isOn ? color.withOpacity(0.08) : const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOn ? color.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isOn ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isOn ? color : Colors.grey, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
            Switch.adaptive(
              value: isOn,
              activeColor: color,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeederSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.restaurant_rounded, color: Color(0xFFFF9500), size: 18),
              SizedBox(width: 8),
              Text(
                'Auto Feeder',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _triggerFeeding,
              icon: const Icon(Icons.restaurant_rounded, size: 18),
              label: const Text('Beri Makan Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9500),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: Color(0xFFFF9500), size: 18),
              SizedBox(width: 8),
              Text(
                'Quick Presets',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _presetButton(
                  label: 'Semua OFF',
                  icon: Icons.power_off_rounded,
                  color: Colors.grey,
                  onTap: () {
                    setState(() {
                      isAutoMode = false;
                      isFanOn = false;
                      isPumpOn = false;
                    });
                    _updateControl('auto_mode', false);
                    _updateControl('fan', false);
                    _updateControl('pump', false);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _presetButton(
                  label: 'Kipas Saja',
                  icon: Icons.air_rounded,
                  color: const Color(0xFF34C759),
                  onTap: () {
                    setState(() {
                      isAutoMode = false;
                      isFanOn = true;
                      isPumpOn = false;
                    });
                    _updateControl('auto_mode', false);
                    _updateControl('fan', true);
                    _updateControl('pump', false);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _presetButton(
                  label: 'Full Cool',
                  icon: Icons.ac_unit_rounded,
                  color: const Color(0xFF007AFF),
                  onTap: () {
                    setState(() {
                      isAutoMode = false;
                      isFanOn = true;
                      isPumpOn = true;
                    });
                    _updateControl('auto_mode', false);
                    _updateControl('fan', true);
                    _updateControl('pump', true);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}