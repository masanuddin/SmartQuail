// [INDO] History Screen - Halaman riwayat data dan grafik
// Menampilkan trend suhu, kelembaban, dan THI dalam bentuk chart

import 'package:flutter/material.dart';
import 'dart:math';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String selectedPeriod = '24 Jam';
  final List<String> periods = ['1 Jam', '24 Jam', '7 Hari', '30 Hari'];

  // [INDO] Data dummy untuk chart (ganti dengan data Supabase nanti)
  List<double> temperatureData = [];
  List<double> humidityData = [];
  List<double> thiData = [];

  @override
  void initState() {
    super.initState();
    _generateDummyData();
  }

  void _generateDummyData() {
    final random = Random();
    temperatureData = List.generate(24, (i) => 25 + random.nextDouble() * 8);
    humidityData = List.generate(24, (i) => 55 + random.nextDouble() * 30);
    thiData = List.generate(24, (i) => 68 + random.nextDouble() * 20);
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
                // Header
                _buildHeader(),
                const SizedBox(height: 20),

                // Period Filter
                _buildPeriodFilter(),
                const SizedBox(height: 20),

                // Temperature Chart
                _buildChartCard(
                  title: 'Suhu',
                  icon: Icons.thermostat_rounded,
                  color: const Color(0xFFFF9500),
                  data: temperatureData,
                  unit: '°C',
                  minY: 20,
                  maxY: 40,
                ),
                const SizedBox(height: 16),

                // Humidity Chart
                _buildChartCard(
                  title: 'Kelembaban',
                  icon: Icons.water_drop_rounded,
                  color: const Color(0xFF007AFF),
                  data: humidityData,
                  unit: '%',
                  minY: 40,
                  maxY: 100,
                ),
                const SizedBox(height: 16),

                // THI Chart
                _buildTHIChartCard(),
                const SizedBox(height: 20),

                // Statistics
                _buildStatistics(),
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
        Icon(Icons.show_chart_rounded, color: Color(0xFF007AFF), size: 28),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat Data',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            Text(
              'Analisis trend suhu & kelembaban',
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

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = period == selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedPeriod = period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<double> data,
    required String unit,
    required double minY,
    required double maxY,
  }) {
    final avg = data.isNotEmpty ? data.reduce((a, b) => a + b) / data.length : 0;
    final min = data.isNotEmpty ? data.reduce((a, b) => a < b ? a : b) : 0;
    final max = data.isNotEmpty ? data.reduce((a, b) => a > b ? a : b) : 0;

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                ],
              ),
              Text(
                'Avg: ${avg.toStringAsFixed(1)}$unit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Simple Chart (Custom Paint)
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: SimpleChartPainter(
                data: data,
                color: color,
                minY: minY,
                maxY: maxY,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Min/Max
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min: ${min.toStringAsFixed(1)}$unit',
                style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
              ),
              Text(
                'Max: ${max.toStringAsFixed(1)}$unit',
                style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTHIChartCard() {
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
              Icon(Icons.speed_rounded, color: Color(0xFF5856D6), size: 20),
              SizedBox(width: 8),
              Text(
                'THI Index',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // THI Chart with zones
          SizedBox(
            height: 140,
            child: CustomPaint(
              size: const Size(double.infinity, 140),
              painter: THIChartPainter(data: thiData),
            ),
          ),
          const SizedBox(height: 12),

          // Zone Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _zoneLegend('Normal', const Color(0xFF34C759)),
              _zoneLegend('Warning', const Color(0xFFFF9500)),
              _zoneLegend('Danger', const Color(0xFFFF3B30)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _zoneLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
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
              Icon(Icons.analytics_rounded, color: Color(0xFF007AFF), size: 20),
              SizedBox(width: 8),
              Text(
                'Statistik',
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
              Expanded(child: _statItem('Rata-rata Suhu', '27.8°C', Icons.thermostat)),
              Expanded(child: _statItem('Rata-rata RH', '70%', Icons.water_drop)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statItem('Rata-rata THI', '74.5', Icons.speed)),
              Expanded(child: _statItem('Cooling Events', '12x', Icons.air)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF8E8E93)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
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
}

// [INDO] Custom Painter untuk chart sederhana
class SimpleChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double minY;
  final double maxY;

  SimpleChartPainter({
    required this.data,
    required this.color,
    required this.minY,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final xStep = size.width / (data.length - 1);
    final yRange = maxY - minY;

    for (var i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = size.height - ((data[i] - minY) / yRange * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// [INDO] Custom Painter untuk THI chart dengan zone warna
class THIChartPainter extends CustomPainter {
  final List<double> data;

  THIChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw zones
    final normalZone = Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4);
    final warningZone = Rect.fromLTWH(0, size.height * 0.3, size.width, size.height * 0.3);
    final dangerZone = Rect.fromLTWH(0, 0, size.width, size.height * 0.3);

    canvas.drawRect(normalZone, Paint()..color = const Color(0xFF34C759).withOpacity(0.15));
    canvas.drawRect(warningZone, Paint()..color = const Color(0xFFFF9500).withOpacity(0.15));
    canvas.drawRect(dangerZone, Paint()..color = const Color(0xFFFF3B30).withOpacity(0.15));

    if (data.isEmpty) return;

    // Draw line
    final paint = Paint()
      ..color = const Color(0xFF5856D6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final xStep = size.width / (data.length - 1);
    const minY = 60.0;
    const maxY = 100.0;
    final yRange = maxY - minY;

    for (var i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = size.height - ((data[i] - minY) / yRange * size.height);

      if (i == 0) {
        path.moveTo(x, y.clamp(0, size.height));
      } else {
        path.lineTo(x, y.clamp(0, size.height));
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
