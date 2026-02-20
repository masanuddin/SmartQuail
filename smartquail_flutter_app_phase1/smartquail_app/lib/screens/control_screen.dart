// [INDO] Control Screen - Halaman kontrol manual
// Untuk mengontrol misting dan kipas secara manual

import 'package:flutter/material.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  bool isAutoMode = true;
  bool isMistingOn = false;
  bool isFanOn = false;
  bool isBuzzerOn = false;

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
                // Header
                _buildHeader(),
                const SizedBox(height: 20),

                // Warning Banner (when manual mode)
                if (!isAutoMode) _buildWarningBanner(),
                const SizedBox(height: 16),

                // Auto Mode Toggle
                _buildAutoModeCard(),
                const SizedBox(height: 20),

                // Manual Controls
                _buildControlSection(),
                const SizedBox(height: 20),

                // Current Status
                _buildStatusCard(),
                const SizedBox(height: 20),

                // Quick Presets
                _buildPresetsSection(),
              ],
            ),
          ),
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
              'Atur sistem pendingin secara manual',
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
                    isAutoMode ? 'Sistem dikontrol berdasarkan THI' : 'Kontrol manual aktif',
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
                  // Reset manual controls when switching to auto
                  isMistingOn = false;
                  isFanOn = false;
                }
              });
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

          // Misting Control
          _buildControlToggle(
            icon: Icons.water_drop_rounded,
            label: 'Sistem Misting',
            subtitle: 'Semprotkan kabut air untuk pendinginan',
            isOn: isMistingOn,
            color: const Color(0xFF007AFF),
            enabled: !isAutoMode,
            onChanged: (value) => setState(() => isMistingOn = value),
          ),
          const Divider(height: 24),

          // Fan Control
          _buildControlToggle(
            icon: Icons.air_rounded,
            label: 'Kipas Pendingin',
            subtitle: 'Sirkulasi udara dalam kandang',
            isOn: isFanOn,
            color: const Color(0xFF34C759),
            enabled: !isAutoMode,
            onChanged: (value) => setState(() => isFanOn = value),
          ),
          const Divider(height: 24),

          // Buzzer Control
          _buildControlToggle(
            icon: Icons.notifications_active_rounded,
            label: 'Buzzer Alert',
            subtitle: 'Notifikasi suara saat bahaya',
            isOn: isBuzzerOn,
            color: const Color(0xFFFF9500),
            enabled: true,
            onChanged: (value) => setState(() => isBuzzerOn = value),
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
              Expanded(child: _statusItem('Mode', isAutoMode ? 'Otomatis' : 'Manual')),
              Expanded(child: _statusItem('Misting', isMistingOn ? 'ON' : 'OFF')),
              Expanded(child: _statusItem('Kipas', isFanOn ? 'ON' : 'OFF')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusItem(String label, String value) {
    final isOn = value == 'ON' || value == 'Otomatis';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isOn ? const Color(0xFF34C759) : const Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
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
                  onTap: () {
                    setState(() {
                      isAutoMode = false;
                      isMistingOn = false;
                      isFanOn = false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _presetButton(
                  label: 'Kipas Saja',
                  icon: Icons.air_rounded,
                  color: const Color(0xFF34C759),
                  onTap: () {
                    setState(() {
                      isAutoMode = false;
                      isMistingOn = false;
                      isFanOn = true;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _presetButton(
                  label: 'Full Cooling',
                  icon: Icons.ac_unit_rounded,
                  color: const Color(0xFF007AFF),
                  onTap: () {
                    setState(() {
                      isAutoMode = false;
                      isMistingOn = true;
                      isFanOn = true;
                    });
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
