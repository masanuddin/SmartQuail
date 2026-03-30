// [INDO] Control Screen - FIREBASE VERSION
// Untuk mengontrol misting dan kipas via Firebase

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  // [INDO] Firebase Database Reference
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  bool isAutoMode = true;
  bool isMistingOn = false;
  bool isFanOn = false;
  bool isExhaustOn = false;
  bool isBuzzerOn = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadControlState();
  }

  // [INDO] Load current control state from Firebase
  Future<void> _loadControlState() async {
    final snapshot = await _database.child('smartquail/controls').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        isAutoMode = data['auto_mode'] ?? true;
        isMistingOn = data['misting'] ?? false;
        isFanOn = data['fan'] ?? false;
        isExhaustOn = data['exhaust'] ?? false;
        isBuzzerOn = data['buzzer'] ?? false;
      });
    }
  }

  // [INDO] Update control ke Firebase
  Future<void> _updateControl(String key, dynamic value) async {
    setState(() => _isLoading = true);
    try {
      await _database.child('smartquail/controls/$key').set(value);
      // [INDO] Juga update timestamp
      await _database.child('smartquail/controls/last_updated').set(
        ServerValue.timestamp,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  // [INDO] Trigger feeding sekali
  Future<void> _triggerFeeding() async {
    setState(() => _isLoading = true);
    try {
      await _database.child('smartquail/controls/feed_now').set(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🍽️ Feeding triggered!'),
          backgroundColor: Color(0xFF34C759),
        ),
      );
      // Reset setelah 3 detik
      await Future.delayed(const Duration(seconds: 3));
      await _database.child('smartquail/controls/feed_now').set(false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
                    const SizedBox(height: 20),
                    if (!isAutoMode) _buildWarningBanner(),
                    const SizedBox(height: 16),
                    _buildAutoModeCard(),
                    const SizedBox(height: 20),
                    _buildControlSection(),
                    const SizedBox(height: 20),
                    _buildFeederSection(),
                    const SizedBox(height: 20),
                    _buildStatusCard(),
                    const SizedBox(height: 20),
                    _buildPresetsSection(),
                  ],
                ),
              ),
            ),
            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
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
              'Atur sistem pendingin via Firebase',
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
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
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
                    isAutoMode ? 'Sistem dikontrol AI/THI' : 'Kontrol manual aktif',
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
              setState(() {
                isAutoMode = value;
                if (isAutoMode) {
                  isMistingOn = false;
                  isFanOn = false;
                  isExhaustOn = false;
                }
              });
              _updateControl('auto_mode', value);
            },
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
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
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

          _buildControlToggle(
            icon: Icons.water_drop_rounded,
            label: 'Sistem Misting',
            subtitle: 'Semprotkan kabut air',
            isOn: isMistingOn,
            color: const Color(0xFF007AFF),
            enabled: !isAutoMode,
            onChanged: (value) {
              setState(() => isMistingOn = value);
              _updateControl('misting', value);
            },
          ),
          const Divider(height: 24),

          _buildControlToggle(
            icon: Icons.air_rounded,
            label: 'Kipas Pendingin',
            subtitle: 'Sirkulasi udara dalam kandang',
            isOn: isFanOn,
            color: const Color(0xFF34C759),
            enabled: !isAutoMode,
            onChanged: (value) {
              setState(() => isFanOn = value);
              _updateControl('fan', value);
            },
          ),
          const Divider(height: 24),

          _buildControlToggle(
            icon: Icons.wind_power_rounded,
            label: 'Kipas Exhaust',
            subtitle: 'Buang gas amonia',
            isOn: isExhaustOn,
            color: const Color(0xFF5856D6),
            enabled: !isAutoMode,
            onChanged: (value) {
              setState(() => isExhaustOn = value);
              _updateControl('exhaust', value);
            },
          ),
          const Divider(height: 24),

          _buildControlToggle(
            icon: Icons.notifications_active_rounded,
            label: 'Buzzer Alert',
            subtitle: 'Notifikasi suara saat bahaya',
            isOn: isBuzzerOn,
            color: const Color(0xFFFF9500),
            enabled: true,
            onChanged: (value) {
              setState(() => isBuzzerOn = value);
              _updateControl('buzzer', value);
            },
          ),
        ],
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
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
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
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _triggerFeeding,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF9500).withOpacity(0.3)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.restaurant, color: Color(0xFFFF9500), size: 32),
                        SizedBox(height: 8),
                        Text(
                          'FEED NOW',
                          style: TextStyle(
                            color: Color(0xFFFF9500),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Kasih makan sekarang',
                          style: TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.schedule, color: Color(0xFF8E8E93), size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Next: 12:00',
                        style: TextStyle(
                          color: Color(0xFF1D1D1F),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Jadwal berikutnya',
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlToggle({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isOn,
    required Color color,
    required bool enabled,
    required Function(bool) onChanged,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
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
    );
  }

  Widget _buildStatusCard() {
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
              Expanded(child: _statusItem('Misting', isMistingOn ? 'ON' : 'OFF')),
              Expanded(child: _statusItem('Kipas', isFanOn ? 'ON' : 'OFF')),
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
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
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
                      isMistingOn = false;
                      isFanOn = false;
                      isExhaustOn = false;
                    });
                    await _updateControl('auto_mode', false);
                    await _updateControl('misting', false);
                    await _updateControl('fan', false);
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
                      isMistingOn = false;
                      isFanOn = true;
                      isExhaustOn = false;
                    });
                    await _updateControl('auto_mode', false);
                    await _updateControl('misting', false);
                    await _updateControl('fan', true);
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
                      isMistingOn = true;
                      isFanOn = true;
                      isExhaustOn = true;
                    });
                    await _updateControl('auto_mode', false);
                    await _updateControl('misting', true);
                    await _updateControl('fan', true);
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
