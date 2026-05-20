// History Screen - Menampilkan data riwayat dari Firebase
// Path: lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedPeriod = 1;

  List<HistoryData> _historyData = [];
  HistoryStats? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<HistoryData> data;

      switch (_selectedPeriod) {
        case 0:
          data = await HistoryService.getLastHour();
          break;
        case 1:
          data = await HistoryService.getLast24Hours();
          break;
        case 2:
          data = await HistoryService.getLast7Days();
          break;
        case 3:
          data = await HistoryService.getLast30Days();
          break;
        default:
          data = await HistoryService.getLast24Hours();
      }

      setState(() {
        _historyData = data;
        _stats = HistoryService.calculateStats(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildPeriodSelector(),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    _buildLoadingState()
                  else if (_errorMessage != null)
                    _buildErrorState()
                  else if (_historyData.isEmpty)
                    _buildEmptyState()
                  else ...[
                    _buildTemperatureChart(),
                    const SizedBox(height: 16),
                    _buildHumidityChart(),
                    const SizedBox(height: 16),
                    _buildThiChart(),
                    const SizedBox(height: 16),
                    _buildStatisticsCard(),
                  ],
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
      children: [
        const Icon(Icons.show_chart_rounded, color: Color(0xFF007AFF), size: 28),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Data',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            Text(
              'Analisis trend suhu & kelembaban',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['1 Jam', '24 Jam', '7 Hari', '30 Hari'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(periods.length, (index) {
          final isSelected = _selectedPeriod == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedPeriod != index) {
                  setState(() => _selectedPeriod = index);
                  _loadData();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  periods[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
          ),
          const SizedBox(height: 16),
          Text('Memuat data riwayat...', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Terjadi kesalahan',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Belum ada data riwayat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Data akan muncul setelah ESP32\nmenyimpan history pertama',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureChart() {
    return _buildChartCard(
      title: 'Suhu',
      icon: Icons.thermostat_outlined,
      iconColor: const Color(0xFFFF9500),
      avgValue: 'Avg: ${_stats?.avgTemp.toStringAsFixed(1) ?? '-'}°C',
      avgColor: const Color(0xFFFF9500),
      minValue: _stats?.minTemp.toStringAsFixed(1) ?? '-',
      maxValue: _stats?.maxTemp.toStringAsFixed(1) ?? '-',
      chart: _buildLineChart(
        data: _historyData.map((e) => e.temperature).toList(),
        lineColor: const Color(0xFFFF9500),
        fillColor: const Color(0xFFFF9500).withOpacity(0.1),
      ),
    );
  }

  Widget _buildHumidityChart() {
    return _buildChartCard(
      title: 'Kelembaban',
      icon: Icons.water_drop_outlined,
      iconColor: const Color(0xFF007AFF),
      avgValue: 'Avg: ${_stats?.avgHumidity.toStringAsFixed(1) ?? '-'}%',
      avgColor: const Color(0xFF007AFF),
      minValue: _stats?.minHumidity.toStringAsFixed(1) ?? '-',
      maxValue: _stats?.maxHumidity.toStringAsFixed(1) ?? '-',
      chart: _buildLineChart(
        data: _historyData.map((e) => e.humidity).toList(),
        lineColor: const Color(0xFF007AFF),
        fillColor: const Color(0xFF007AFF).withOpacity(0.1),
      ),
    );
  }

  Widget _buildThiChart() {
    return _buildChartCard(
      title: 'THI Index',
      icon: Icons.speed_outlined,
      iconColor: const Color(0xFF5856D6),
      avgValue: 'Avg: ${_stats?.avgThi.toStringAsFixed(1) ?? '-'}',
      avgColor: const Color(0xFF5856D6),
      minValue: null,
      maxValue: null,
      chart: _buildThiZoneChart(),
      showLegend: true,
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String avgValue,
    required Color avgColor,
    required String? minValue,
    required String? maxValue,
    required Widget chart,
    bool showLegend = false,
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
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
                avgValue,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: avgColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ✅ ClipRect mencegah rangeAnnotation THI overflow ke card lain
          SizedBox(
            height: 160,
            child: ClipRect(child: chart),
          ),
          if (minValue != null && maxValue != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Min: $minValue${title == 'Kelembaban' ? '%' : '°C'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  'Max: $maxValue${title == 'Kelembaban' ? '%' : '°C'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
          if (showLegend) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Normal', const Color(0xFF34C759)),
                const SizedBox(width: 16),
                _buildLegendItem('Warning', const Color(0xFFFF9500)),
                const SizedBox(width: 16),
                _buildLegendItem('Danger', const Color(0xFFFF3B30)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildLineChart({
    required List<double> data,
    required Color lineColor,
    required Color fillColor,
  }) {
    if (data.isEmpty) return const Center(child: Text('Tidak ada data'));

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    // Padding 15% dari range agar garis tidak kepotong ClipRect
    final dataMin = data.reduce((a, b) => a < b ? a : b);
    final dataMax = data.reduce((a, b) => a > b ? a : b);
    final range = (dataMax - dataMin).clamp(1.0, double.infinity);
    final pad = range * 0.15;

    return LineChart(
      LineChartData(
        minY: dataMin - pad,
        maxY: dataMax + pad,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (range / 3).clamp(1.0, double.infinity), // ✅ interval dinamis
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: lineColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            // ✅ Double-guard agar dot benar-benar tidak muncul
            dotData: FlDotData(
              show: false,
              checkToShowDot: (_, __) => false,
            ),
            belowBarData: BarAreaData(show: true, color: fillColor),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.black87,
            tooltipMargin: 8,
            fitInsideHorizontally: true, // ✅ tooltip tidak keluar kiri/kanan
            fitInsideVertically: true,   // ✅ tooltip tidak keluar atas/bawah
            getTooltipItems: (spots) => spots.map((spot) {
              return LineTooltipItem(
                spot.y.toStringAsFixed(1),
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildThiZoneChart() {
    if (_historyData.isEmpty) return const Center(child: Text('Tidak ada data'));

    final thiValues = _historyData.map((e) => e.thi).toList();
    final spots = _historyData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.thi);
    }).toList();

    final dataMin = thiValues.reduce((a, b) => a < b ? a : b);
    final dataMax = thiValues.reduce((a, b) => a > b ? a : b);
    final range = (dataMax - dataMin).clamp(1.0, double.infinity);
    final pad = range * 0.15;
    final minY = dataMin - pad;
    final maxY = dataMax + pad;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            HorizontalRangeAnnotation(
              y1: minY,
              y2: 72,
              color: const Color(0xFF34C759).withOpacity(0.15),
            ),
            HorizontalRangeAnnotation(
              y1: 72,
              y2: 78,
              color: const Color(0xFFFF9500).withOpacity(0.15),
            ),
            HorizontalRangeAnnotation(
              y1: 78,
              y2: maxY,
              color: const Color(0xFFFF3B30).withOpacity(0.15),
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: const Color(0xFF5856D6),
            barWidth: 2.5,
            isStrokeCapRound: true,
            // ✅ Double-guard dot
            dotData: FlDotData(
              show: false,
              checkToShowDot: (_, __) => false,
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.black87,
            tooltipMargin: 8,
            fitInsideHorizontally: true, // ✅
            fitInsideVertically: true,   // ✅
            getTooltipItems: (spots) => spots.map((spot) {
              String status = 'Normal';
              if (spot.y > 78) status = 'Danger';
              else if (spot.y > 72) status = 'Warning';
              return LineTooltipItem(
                'THI: ${spot.y.toStringAsFixed(1)}\n$status',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
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
              Icon(Icons.analytics_outlined, color: Color(0xFF007AFF), size: 20),
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
              Expanded(
                child: _buildStatItem(
                  icon: Icons.thermostat_outlined,
                  value: '${_stats?.avgTemp.toStringAsFixed(1) ?? '-'}°C',
                  label: 'Rata-rata Suhu',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.water_drop_outlined,
                  value: '${_stats?.avgHumidity.toStringAsFixed(0) ?? '-'}%',
                  label: 'Rata-rata RH',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.speed_outlined,
                  value: _stats?.avgThi.toStringAsFixed(1) ?? '-',
                  label: 'Rata-rata THI',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.ac_unit_outlined,
                  value: '${_stats?.coolingEvents ?? 0}x',
                  label: 'Cooling Events',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF8E8E93), size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}