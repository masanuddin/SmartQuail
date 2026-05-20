// [INDO] Settings Screen - Halaman pengaturan aplikasi
// Untuk mengatur threshold, notifikasi, dan preferensi lainnya
// UPDATED: Tambah User Info dan Logout

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'info_screen.dart'; // ✅ NEW

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Threshold settings
  double thiNormal = 65.0;
  double thiWarning = 78.0;
  double thiDanger = 85.0;

  // Notification settings
  bool pushNotification = true;
  bool soundAlert = true;
  bool emailAlert = false;

  // App settings
  String language = 'Indonesia';
  String theme = 'Light';

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
                const SizedBox(height: 24),

                // ✅ NEW: User Info Section
                _buildSectionTitle('Akun'),
                _buildUserCard(),
                const SizedBox(height: 24),

                // Device Section
                _buildSectionTitle('Perangkat'),
                _buildDeviceCard(),
                const SizedBox(height: 24),

                // THI Threshold Section
                _buildSectionTitle('Threshold THI'),
                _buildThresholdCard(),
                const SizedBox(height: 24),

                // Notification Section
                _buildSectionTitle('Notifikasi'),
                _buildNotificationCard(),
                const SizedBox(height: 24),

                // App Section
                _buildSectionTitle('Aplikasi'),
                _buildAppSettingsCard(),
                const SizedBox(height: 24),

                // About Section
                _buildAboutCard(),
                const SizedBox(height: 24),

                // ✅ NEW: Logout Button
                _buildLogoutButton(),
                const SizedBox(height: 24),

                // Version info
                _buildVersionInfo(),
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
        Icon(Icons.settings_rounded, color: Color(0xFF8E8E93), size: 28),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengaturan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            Text(
              'Konfigurasi aplikasi dan perangkat',
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8E8E93),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ✅ NEW: User Card with account info
  Widget _buildUserCard() {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user?.isAnonymous ?? true;
    final phoneNumber = user?.phoneNumber ?? '';

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
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isGuest 
                  ? const Color(0xFF8E8E93).withOpacity(0.1)
                  : const Color(0xFF007AFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              isGuest ? Icons.person_outline : Icons.person,
              color: isGuest ? const Color(0xFF8E8E93) : const Color(0xFF007AFF),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGuest ? 'Pengguna Tamu' : phoneNumber,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isGuest ? 'Login untuk fitur lengkap' : 'Akun terverifikasi',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Badge
          if (!isGuest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: Color(0xFF34C759), size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF34C759),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard() {
    return Container(
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
        children: [
          _buildSettingsItem(
            icon: Icons.label_outline_rounded,
            label: 'Nama Kandang',
            value: 'Kandang 1',
            onTap: () {},
          ),
          _divider(),
          _buildSettingsItem(
            icon: Icons.memory_rounded,
            label: 'Device ID',
            value: 'ESP32-01',
            onTap: () {},
          ),
          _divider(),
          _buildSettingsItem(
            icon: Icons.wifi_rounded,
            label: 'Status Koneksi',
            value: 'Online',
            valueColor: const Color(0xFF34C759),
            onTap: () {},
          ),
          _divider(),
          _buildSettingsItem(
            icon: Icons.link_rounded,
            label: 'Firebase URL',
            value: 'Connected',
            valueColor: const Color(0xFF34C759),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdCard() {
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
        children: [
          // Normal Threshold
          _buildThresholdSlider(
            label: 'Normal (Hijau)',
            value: thiNormal,
            min: 60,
            max: 75,
            color: const Color(0xFF34C759),
            description: 'THI di bawah nilai ini = Normal',
            onChanged: (value) => setState(() => thiNormal = value),
          ),
          const SizedBox(height: 20),

          // Warning Threshold
          _buildThresholdSlider(
            label: 'Warning (Kuning)',
            value: thiWarning,
            min: 72,
            max: 82,
            color: const Color(0xFFFF9500),
            description: 'THI di atas Normal sampai nilai ini = Warning',
            onChanged: (value) => setState(() => thiWarning = value),
          ),
          const SizedBox(height: 20),

          // Danger Threshold
          _buildThresholdSlider(
            label: 'Danger (Merah)',
            value: thiDanger,
            min: 78,
            max: 95,
            color: const Color(0xFFFF3B30),
            description: 'THI di atas Warning = Danger',
            onChanged: (value) => setState(() => thiDanger = value),
          ),

          const SizedBox(height: 16),
          // Reset button
          TextButton(
            onPressed: () {
              setState(() {
                thiNormal = 65.0;
                thiWarning = 78.0;
                thiDanger = 85.0;
              });
            },
            child: const Text(
              'Reset ke Default',
              style: TextStyle(color: Color(0xFF007AFF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Color color,
    required String description,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.1),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        Text(
          description,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard() {
    return Container(
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
        children: [
          _buildSwitchItem(
            icon: Icons.notifications_active_outlined,
            label: 'Push Notification',
            subtitle: 'Terima notifikasi peringatan',
            value: pushNotification,
            onChanged: (val) => setState(() => pushNotification = val),
          ),
          _divider(),
          _buildSwitchItem(
            icon: Icons.volume_up_outlined,
            label: 'Suara Peringatan',
            subtitle: 'Bunyi saat kondisi bahaya',
            value: soundAlert,
            onChanged: (val) => setState(() => soundAlert = val),
          ),
          _divider(),
          _buildSwitchItem(
            icon: Icons.email_outlined,
            label: 'Email Alert',
            subtitle: 'Kirim laporan via email',
            value: emailAlert,
            onChanged: (val) => setState(() => emailAlert = val),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsCard() {
    return Container(
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
        children: [
          _buildSettingsItem(
            icon: Icons.language_rounded,
            label: 'Bahasa',
            value: language,
            onTap: () => _showLanguageDialog(),
          ),
          _divider(),
          _buildSettingsItem(
            icon: Icons.palette_rounded,
            label: 'Tema',
            value: theme,
            onTap: () => _showThemeDialog(),
          ),
          _divider(),
          _buildSettingsItem(
            icon: Icons.timer_rounded,
            label: 'Interval Update',
            value: '2 detik',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
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
        children: [
          _buildSettingsItem(
            icon: Icons.info_outline_rounded,
            label: 'Tentang Aplikasi',
            value: '',
            showArrow: true,
            onTap: () => _showAboutDialog(),
          ),
          _divider(),
          _buildSettingsItem(
            icon: Icons.help_outline_rounded,
            label: 'Bantuan',
            value: '',
            showArrow: true,
            // ✅ FIXED: navigate ke InfoScreen tab Bantuan
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InfoScreen(initialTab: 0),
              ),
            ),
          ),
          _divider(),
          _buildSettingsItem(
            icon: Icons.privacy_tip_outlined,
            label: 'Kebijakan Privasi',
            value: '',
            showArrow: true,
            // ✅ FIXED: navigate ke InfoScreen tab Kebijakan Privasi
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InfoScreen(initialTab: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Logout Button
  Widget _buildLogoutButton() {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showLogoutDialog,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFFF3B30),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Keluar dari Akun',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFFF3B30),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFFF3B30),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ NEW: Logout Dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Keluar dari Akun'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF8E8E93)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.signOut();
              // AuthWrapper akan auto redirect ke Login
            },
            child: const Text(
              'Keluar',
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool showArrow = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8E8E93), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ),
            if (value.isNotEmpty)
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor ?? const Color(0xFF8E8E93),
                ),
              ),
            if (showArrow)
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8E8E93),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8E8E93), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: const Color(0xFF34C759),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 52);
  }

  Widget _buildVersionInfo() {
    return const Center(
      child: Column(
        children: [
          Text(
            'SmartQuail v1.0.0',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF8E8E93),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'BINUS University © 2026',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFFAEAEB2),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Pilih Bahasa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('🇮🇩 Indonesia'),
              onTap: () {
                setState(() => language = 'Indonesia');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('🇬🇧 English'),
              onTap: () {
                setState(() => language = 'English');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Pilih Tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light'),
              onTap: () {
                setState(() => theme = 'Light');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark'),
              onTap: () {
                setState(() => theme = 'Dark');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('🐦', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            const Text('SmartQuail'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IoT-Based Intelligent Climate Control System for Quail Farming',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 16),
            Text('Developers:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Ricky Rudiansyah'),
            Text('• Marcellino Asanuddin'),
            SizedBox(height: 12),
            Text('Supervisor:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Prof. Dr. Ir. Widodo Budiharto'),
            SizedBox(height: 12),
            Text('Version: 1.0.0'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}