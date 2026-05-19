// [INDO] Status Banner Widget - Banner untuk menampilkan status sistem
// Berubah warna berdasarkan status: normal (hijau), warning (kuning), danger (merah)

import 'package:flutter/material.dart';

class StatusBanner extends StatelessWidget {
  final String status; // normal, warning, danger
  final double thi;

  const StatusBanner({
    super.key,
    required this.status,
    required this.thi,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _icon,
              color: _iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: _subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          // THI Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'THI ${thi.toStringAsFixed(1)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: _iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [INDO] Getter untuk warna background berdasarkan status
  Color get _backgroundColor {
    switch (status) {
      case 'warning':
        return const Color(0xFFFFF3E0);
      case 'danger':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFE8F5E9);
    }
  }

  Color get _borderColor {
    switch (status) {
      case 'warning':
        return const Color(0xFFFF9500).withOpacity(0.3);
      case 'danger':
        return const Color(0xFFFF3B30).withOpacity(0.3);
      default:
        return const Color(0xFF34C759).withOpacity(0.3);
    }
  }

  Color get _iconBackgroundColor {
    switch (status) {
      case 'warning':
        return const Color(0xFFFF9500).withOpacity(0.15);
      case 'danger':
        return const Color(0xFFFF3B30).withOpacity(0.15);
      default:
        return const Color(0xFF34C759).withOpacity(0.15);
    }
  }

  Color get _iconColor {
    switch (status) {
      case 'warning':
        return const Color(0xFFFF9500);
      case 'danger':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF34C759);
    }
  }

  Color get _textColor {
    switch (status) {
      case 'warning':
        return const Color(0xFFE65100);
      case 'danger':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  Color get _subtitleColor {
    switch (status) {
      case 'warning':
        return const Color(0xFFEF6C00);
      case 'danger':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF388E3C);
    }
  }

  IconData get _icon {
    switch (status) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'danger':
        return Icons.error_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  String get _title {
    switch (status) {
      case 'warning':
        return '⚠️ Perhatian - Kipas Aktif';
      case 'danger':
        return '🚨 Bahaya - Pendinginan Aktif';
      default:
        return '✓ Sistem Normal';
    }
  }

  String get _subtitle {
    switch (status) {
      case 'warning':
        return 'THI memasuki zona warning, kipas dinyalakan';
      case 'danger':
        return 'THI tinggi! Misting dan kipas aktif';
      default:
        return 'Kondisi kandang dalam batas aman';
    }
  }
}
