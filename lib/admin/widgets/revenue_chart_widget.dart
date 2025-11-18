import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../core/utils/delivery_price_utils.dart';

class RevenueChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> monthlyStats;
  final double height;

  const RevenueChartWidget({
    super.key,
    required this.monthlyStats,
    this.height = 250,
  });

  @override
  State<RevenueChartWidget> createState() => _RevenueChartWidgetState();
}

class _RevenueChartWidgetState extends State<RevenueChartWidget> {
  bool _isDateFormatInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('fr_FR');
    if (mounted) {
      setState(() {
        _isDateFormatInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!_isDateFormatInitialized) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
      );
    }

    if (widget.monthlyStats.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 48,
                color: colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune donnée disponible',
                style: GoogleFonts.montserrat(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Les graphiques apparaîtront quand des revenus seront générés',
                style: GoogleFonts.montserrat(
                  color: colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Évolution des Revenus (12 derniers mois)',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              _buildLineChartData(colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData(ColorScheme colorScheme) {
    final spots = _generateSpots();
    final maxY = _getMaxY();
    final minY = _getMinY();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY > 0 ? maxY / 4 : 25,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: colorScheme.outline.withOpacity(0.1),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (double value, TitleMeta meta) {
              return _buildBottomTitle(value.toInt(), colorScheme);
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: maxY > 0 ? maxY / 4 : 25,
            reservedSize: 60,
            getTitlesWidget: (double value, TitleMeta meta) {
              return _buildLeftTitle(value, colorScheme);
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      minX: 0,
      maxX: (widget.monthlyStats.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.8),
              colorScheme.primary,
            ],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: colorScheme.primary,
                strokeWidth: 2,
                strokeColor: colorScheme.surface,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withOpacity(0.1),
                colorScheme.primary.withOpacity(0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => colorScheme.inverseSurface,
          tooltipRoundedRadius: 8,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final monthData = widget.monthlyStats[barSpot.x.toInt()];
              final periodStartStr = monthData['start_date'] ?? monthData['period_start'];
              
              if (periodStartStr == null) {
                return null;
              }
              
              final periodStart = DateTime.parse(periodStartStr);
              final monthName = DateFormat('MMM yyyy', 'fr_FR').format(periodStart);
              
              return LineTooltipItem(
                '$monthName\n${DeliveryPriceUtils.formatPrice(barSpot.y)}',
                GoogleFonts.montserrat(
                  color: colorScheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    return widget.monthlyStats.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final revenue = (data['revenue'] ?? data['total_revenue'] as num?)?.toDouble() ?? 0.0;
      return FlSpot(index.toDouble(), revenue);
    }).toList();
  }

  double _getMaxY() {
    if (widget.monthlyStats.isEmpty) return 100;
    
    final maxRevenue = widget.monthlyStats
        .map((data) => (data['revenue'] ?? data['total_revenue'] as num?)?.toDouble() ?? 0.0)
        .reduce((a, b) => a > b ? a : b);
    
    // S'assurer qu'on a une valeur minimale pour éviter horizontalInterval = 0
    if (maxRevenue <= 0) return 100;
    
    // Ajouter 20% de marge au maximum
    return maxRevenue * 1.2;
  }

  double _getMinY() {
    if (widget.monthlyStats.isEmpty) return 0;
    
    final minRevenue = widget.monthlyStats
        .map((data) => (data['revenue'] ?? data['total_revenue'] as num?)?.toDouble() ?? 0.0)
        .reduce((a, b) => a < b ? a : b);
    
    // Retourner 0 si le minimum est positif, sinon ajouter une marge
    return minRevenue >= 0 ? 0 : minRevenue * 1.2;
  }

  Widget _buildBottomTitle(int index, ColorScheme colorScheme) {
    if (index < 0 || index >= widget.monthlyStats.length) {
      return const SizedBox.shrink();
    }

    final monthData = widget.monthlyStats[index];
    final periodStartStr = monthData['start_date'] ?? monthData['period_start'];
    
    if (periodStartStr == null) {
      return const SizedBox.shrink();
    }
    
    final periodStart = DateTime.parse(periodStartStr);
    final monthAbbr = DateFormat('MMM', 'fr_FR').format(periodStart);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        monthAbbr,
        style: GoogleFonts.montserrat(
          color: colorScheme.onSurface.withOpacity(0.6),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLeftTitle(double value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        _formatCompactPrice(value),
        style: GoogleFonts.montserrat(
          color: colorScheme.onSurface.withOpacity(0.6),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatCompactPrice(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}