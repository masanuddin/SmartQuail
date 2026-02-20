// [INDO] THI Gauge Widget - FIXED VERSION
// Fix: Angka tidak ketimpa badge DANGER

import 'package:flutter/material.dart';
import 'dart:math' as math;

class THIGauge extends StatefulWidget {
  final double value;
  final double minValue;
  final double maxValue;

  const THIGauge({
    super.key,
    required this.value,
    this.minValue = 60,
    this.maxValue = 100,
  });

  @override
  State<THIGauge> createState() => _THIGaugeState();
}

class _THIGaugeState extends State<THIGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(THIGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    _animation = Tween<double>(
      begin: _currentValue,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ))
      ..addListener(() {
        setState(() {
          _currentValue = _animation.value;
        });
      });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getValueColor() {
    if (_currentValue < 72) {
      return const Color(0xFF34C759);
    } else if (_currentValue < 78) {
      return const Color(0xFFFF9500);
    } else {
      return const Color(0xFFFF3B30);
    }
  }

  String _getStatusText() {
    if (_currentValue < 72) {
      return 'NORMAL';
    } else if (_currentValue < 78) {
      return 'WARNING';
    } else {
      return 'DANGER';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gauge Arc - posisi lebih ke atas
          Positioned(
            top: 0,
            child: CustomPaint(
              size: const Size(240, 140),
              painter: _GaugePainter(
                value: _currentValue,
                minValue: widget.minValue,
                maxValue: widget.maxValue,
              ),
            ),
          ),
          // Center Value Display - posisi di bawah gauge
          Positioned(
            top: 70,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Angka THI
                Text(
                  _currentValue.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: _getValueColor(),
                    height: 1.0,
                  ),
                ),
                // Spasi antara angka dan badge
                const SizedBox(height: 8),
                // Badge Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getValueColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _getValueColor(),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double minValue;
  final double maxValue;

  _GaugePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 20;

    // Background arc
    final bgPaint = Paint()
      ..color = const Color(0xFFE5E5EA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Colored zones
    _drawZoneArc(canvas, center, radius, 60, 72, const Color(0xFF34C759).withOpacity(0.25));
    _drawZoneArc(canvas, center, radius, 72, 78, const Color(0xFFFF9500).withOpacity(0.25));
    _drawZoneArc(canvas, center, radius, 78, 100, const Color(0xFFFF3B30).withOpacity(0.25));

    // Value arc
    final valueRatio = (value.clamp(minValue, maxValue) - minValue) / (maxValue - minValue);
    final sweepAngle = math.pi * valueRatio;

    Color arcColor;
    if (value < 72) {
      arcColor = const Color(0xFF34C759);
    } else if (value < 78) {
      arcColor = const Color(0xFFFF9500);
    } else {
      arcColor = const Color(0xFFFF3B30);
    }

    final valuePaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweepAngle,
      false,
      valuePaint,
    );

    // Draw tick marks
    _drawTicks(canvas, center, radius);

    // Draw labels
    _drawLabels(canvas, center, radius, size);
  }

  void _drawZoneArc(Canvas canvas, Offset center, double radius, double start, double end, Color color) {
    final startRatio = (start - minValue) / (maxValue - minValue);
    final endRatio = (end - minValue) / (maxValue - minValue);
    final startAngle = math.pi + (math.pi * startRatio);
    final sweepAngle = math.pi * (endRatio - startRatio);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    final tickPaint = Paint()
      ..color = const Color(0xFFAEAEB2)
      ..strokeWidth = 2;

    for (var i = 0; i <= 4; i++) {
      final angle = math.pi + (math.pi * i / 4);
      final innerRadius = radius - 28;
      final outerRadius = radius - 20;

      final innerPoint = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final outerPoint = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );

      canvas.drawLine(innerPoint, outerPoint, tickPaint);
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double radius, Size size) {
    final textStyle = const TextStyle(
      color: Color(0xFF8E8E93),
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    // Min label (60)
    final minPainter = TextPainter(
      text: TextSpan(text: '60', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    minPainter.paint(canvas, Offset(8, size.height - 5));

    // Max label (100)
    final maxPainter = TextPainter(
      text: TextSpan(text: '100', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    maxPainter.paint(canvas, Offset(size.width - 30, size.height - 5));
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}