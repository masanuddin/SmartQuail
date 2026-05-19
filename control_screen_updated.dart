// [INDO] Control Screen - UPDATED VERSION
// Sinkron dengan ESP32 Firebase structure
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
  
  // State variables - SINKRON dengan ESP32
  bool isAutoMode = true;
  bool isFanOn = false;
  bool isPumpOn = false;      // Ganti dari isMistingOn
  bool isExhaustOn = false;
  bool isBuzzerOn = false;
  bool _isLoading = false;

  // Untuk monitor data dari device
  double temperature = 0;
  double humidity = 0;
  double thi = 0;
  int amonia = 0;
  bool isOnline = false;

  StreamSubscription<DatabaseEvent>? _deviceSubscription;
  StreamSubscription<DatabaseEvent>? _controlSubscription;

  @override
  void initState() {
    super.initState();
    _listenToDevice();
    _listenToControls();
  }

  @override
  void dispose() {
    _deviceSubscription?.cancel();
    _controlSubscription?.cancel();
    super.dispose();
  }

  // [INDO] Listen ke data device dari ESP32
  void _listenToDevice() {
    _deviceSubscription = _database
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
          isOnline = data['online'] ?? false;
          
          // Baca status relay dari device (actual state)
          isFanOn = data['relay_fan'] ?? false;
          isPumpOn = data['relay_pump'] ?? false;
          isAutoMode = data['auto_mode'] ?? true;
        });
      }
    });
  }

  // [INDO] Listen ke controls (untuk sync antar device)
  void _listenToControls() {
    _controlSubscription = _database
        .child('smartquail/controls')
        .onValue
        .listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          // Hanya update jika manual mode
          if (!isAutoMode) {
            isExhaustOn = data['exhaust'] ?? false;
            isBuzzerOn = data['buzzer'] ?? false;
          }
        });
      }
    });
  }

  // [INDO] Update control ke Firebase
  Future<void> _updateControl(String key, dynamic value) async {
    setState(() => _isLoading = true);
    try {
      await _database.child('smartquail/controls/$key').set(value);
      await _database.child('smartquail/controls/last_updated').set(
        ServerValue.timestamp,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  // [INDO] Trigger feeding sekali
  Future<void> _triggerFeeding() async {
    setState(() => _isLoading = true);
    try {
      await _database.child('smartquail/controls/feed_now').set(true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🍽️ Feeding triggered!'),
            backgroundColor: Color(0xFF34C759),
          ),
        );
      }
      await Future.delayed(const Duration(seconds: 3));
      await _database.child('smartquail/controls/feed_now').set(false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildConnectionStatus(),
                    const SizedBox(height: 16),
                    if (!isAutoMode) _buildWarningBanner(),
                    if (!isAutoMode) const SizedBox(height: 16),
                    _buildAutoModeCard(),
                    const SizedBox(height: 20),
                    _buildSensorMonitor(),
                    const SizedBox(height: 20),
                    _buildControlSection(),
                    const SizedBox(height: 20),
                    _buildFeederSection(),
                    const SizedBox(height: 20),
                    _buildStatusCard(),
                    const SizedBox(height: 20),
                    _buildPresetsSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Icon(Icons.tune_rounded, color: Color(0xFF5856D6), size: 28),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kontrol Manual',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            Text(
              'Atur kipas dan pompa via Firebase',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isOnline 
            ? const Color(0xFF34C759).withOpacity(0.1)
            : const Color(0xFFFF3B30).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
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
          const SizedBox(width: 8),
          Text(
            isOnline ? 'ESP32 Online' : 'ESP32 Offline',
            style: TextStyle(
              color: isOnline ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9500).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9500).withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9500), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode Manual Aktif',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF9500),
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Kontrol otomatis dinonaktifkan. Pastikan memantau kondisi kandang.',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isAutoMode 
                      ? const Color(0xFF34C759).withOpacity(0.1)
                      : const Color(0xFFFF9500).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isAutoMode ? Icons.autorenew_rounded : Icons.pan_tool_rounded,
                  color: isAutoMode ? const Color(0xFF34C759) : const Color(0xFFFF9500),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mode Otomatis',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  Text(
                    isAutoMode ? 'Dikontrol berdasarkan THI' : 'Kontrol manual aktif',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sensors_rounded, color: Color(0xFF007AFF), size: 20),
              SizedBox(width: 8),
              Text(
                'Monitor Sensor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _sensorItem('Suhu', '${temperature.toStringAsFixed(1)}°C', Icons.thermostat_rounded, const Color(0xFFFF9500))),
              Expanded(child: _sensorItem('Humid', '${humidity.toStringAsFixed(0)}%', Icons.water_drop_rounded, const Color(0xFF007AFF))),
              Expanded(child: _sensorItem('THI', thi.toStringAsFixed(1), Icons.speed_rounded, const Color(0xFF5856D6))),
              Expanded(child: _sensorItem('NH₃', '$amonia ppm', Icons.cloud_rounded, amonia > 50 ? Colors.red : (amonia > 25 ? Colors.orange : const Color(0xFF34C759)))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sensorItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings_remote_rounded, color: Color(0xFF5856D6), size: 20),
              SizedBox(width: 8),
              Text(
                'Kontrol Perangkat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildControlTile(
            label: 'Kipas Pendingin',
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
          const SizedBox(height: 12),
          _buildControlTile(
            label: 'Pompa Air / Misting',
            subtitle: 'Semprotkan kabut untuk pendinginan',
            icon: Icons.water_drop_rounded,
            color: const Color(0xFF007AFF),
            isOn: isPumpOn,
            enabled: !isAutoMode,
            onChanged: (value) {
              setState(() => isPumpOn = value);
              _updateControl('pump', value);
            },
          ),
          const SizedBox(height: 12),
          _buildControlTile(
            label: 'Exhaust Fan',
            subtitle: 'Buang udara panas & gas amonia',
            icon: Icons.wind_power_rounded,
            color: const Color(0xFF5856D6),
            isOn: isExhaustOn,
            enabled: !isAutoMode,
            onChanged: (value) {
              setState(() => isExhaustOn = value);
              _updateControl('exhaust', value);
            },
          ),
          const SizedBox(height: 12),
          _buildControlTile(
            label: 'Buzzer Alarm',
            subtitle: 'Notifikasi suara darurat',
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFFFF3B30),
            isOn: isBuzzerOn,
            enabled: !isAutoMode,
            onChanged: (value) {
              setState(() => isBuzzerOn = value);
              _updateControl('buzzer', value);
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOn ? color.withOpacity(0.08) : const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOn ? color.withOpacity(0.3) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isOn ? color.withOpacity(0.15) : const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isOn ? color : const Color(0xFF8E8E93), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.restaurant_rounded, color: Color(0xFFFF9500), size: 20),
              SizedBox(width: 8),
              Text(
                'Auto Feeder',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _triggerFeeding,
              icon: const Icon(Icons.restaurant_rounded),
              label: const Text('Beri Makan Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9500),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF007AFF), size: 20),
              SizedBox(width: 8),
              Text(
                'Status Saat Ini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statusItem('Mode', isAutoMode ? 'Auto' : 'Manual')),
              Expanded(child: _statusItem('Kipas', isFanOn ? 'ON' : 'OFF')),
              Expanded(child: _statusItem('Pompa', isPumpOn ? 'ON' : 'OFF')),
              Expanded(child: _statusItem('Exhaust', isExhaustOn ? 'ON' : 'OFF')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusItem(String label, String value) {
    final isOn = value == 'ON' || value == 'Auto';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isOn ? const Color(0xFF34C759) : const Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: Color(0xFFFF9500), size: 20),
              SizedBox(width: 8),
              Text(
                'Quick Presets',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _presetButton(
                  label: 'Semua OFF',
                  icon: Icons.power_off_rounded,
                  color: const Color(0xFF8E8E93),
                  onTap: () async {
                    setState(() {
                      isAutoMode = false;
                      isFanOn = false;
                      isPumpOn = false;
                      isExhaustOn = false;
                    });
                    await _updateControl('auto_mode', false);
                    await _updateControl('fan', false);
                    await _updateControl('pump', false);
                    await _updateControl('exhaust', false);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _presetButton(
                  label: 'Kipas Saja',
                  icon: Icons.air_rounded,
                  color: const Color(0xFF34C759),
                  onTap: () async {
                    setState(() {
                      isAutoMode = false;
                      isFanOn = true;
                      isPumpOn = false;
                      isExhaustOn = false;
                    });
                    await _updateControl('auto_mode', false);
                    await _updateControl('fan', true);
                    await _updateControl('pump', false);
                    await _updateControl('exhaust', false);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _presetButton(
                  label: 'Full Cool',
                  icon: Icons.ac_unit_rounded,
                  color: const Color(0xFF007AFF),
                  onTap: () async {
                    setState(() {
                      isAutoMode = false;
                      isFanOn = true;
                      isPumpOn = true;
                      isExhaustOn = true;
                    });
                    await _updateControl('auto_mode', false);
                    await _updateControl('fan', true);
                    await _updateControl('pump', true);
                    await _updateControl('exhaust', true);
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
