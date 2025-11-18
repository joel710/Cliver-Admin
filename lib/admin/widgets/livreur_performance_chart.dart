import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/delivery_price_utils.dart';

class LivreurPerformanceChart extends StatelessWidget {
  final List<Map<String, dynamic>> livreurMetrics;
  final double height;

  const LivreurPerformanceChart({
    super.key,
    required this.livreurMetrics,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (livreurMetrics.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 48,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune donnée de performance',
                style: GoogleFonts.montserrat(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Performance des Livreurs (Top 10)',
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
            child: BarChart(
              _buildBarChartData(colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  BarChartData _buildBarChartData(ColorScheme colorScheme) {
    final maxY = _getMaxCommission();
    final barGroups = _generateBarGroups(colorScheme);

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => colorScheme.inverseSurface,
          tooltipRoundedRadius: 8,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final livreur = livreurMetrics[groupIndex];
            final profile = livreur['user_profile'] as Map<String, dynamic>?;
            final name = profile?['fullname'] ?? 'Livreur inconnu';
            final totalCommissions = (livreur['total_commissions'] as num?)?.toDouble() ?? 0;
            final totalMissions = livreur['total_missions'] as int? ?? 0;
            
            return BarTooltipItem(
              '$name\n${DeliveryPriceUtils.formatPrice(totalCommissions)}\n$totalMissions missions',
              GoogleFonts.montserrat(
                color: colorScheme.onInverseSurface,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            );
          },
        ),
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
            reservedSize: 40,
            getTitlesWidget: (double value, TitleMeta meta) {
              return _buildBottomTitle(value.toInt(), colorScheme);
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: maxY > 0 ? maxY / 5 : 20,
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
      barGroups: barGroups,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY > 0 ? maxY / 5 : 20,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: colorScheme.outline.withValues(alpha: 0.1),
            strokeWidth: 1,
          );
        },
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups(ColorScheme colorScheme) {
    return livreurMetrics.asMap().entries.map((entry) {
      final index = entry.key;
      final livreur = entry.value;
      final totalCommissions = (livreur['total_commissions'] as num?)?.toDouble() ?? 0;
      
      Color barColor = colorScheme.primary;
      if (index == 0) barColor = Colors.amber; // Premier
      if (index == 1) barColor = Colors.grey; // Deuxième
      if (index == 2) barColor = Colors.orange; // Troisième

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: totalCommissions,
            color: barColor,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            gradient: LinearGradient(
              colors: [
                barColor.withValues(alpha: 0.7),
                barColor,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxCommission() {
    if (livreurMetrics.isEmpty) return 100;
    
    final maxCommission = livreurMetrics
        .map((livreur) => (livreur['total_commissions'] as num?)?.toDouble() ?? 0.0)
        .reduce((a, b) => a > b ? a : b);
    
    // S'assurer qu'on a une valeur minimale pour éviter horizontalInterval = 0
    if (maxCommission <= 0) return 100;
    
    // Ajouter 20% de marge au maximum
    return maxCommission * 1.2;
  }

  Widget _buildBottomTitle(int index, ColorScheme colorScheme) {
    if (index < 0 || index >= livreurMetrics.length) {
      return const SizedBox.shrink();
    }

    final livreur = livreurMetrics[index];
    final profile = livreur['user_profile'] as Map<String, dynamic>?;
    final name = profile?['fullname'] ?? 'L${index + 1}';
    
    // Prendre seulement les initiales ou les premiers caractères
    final shortName = name.length > 8 ? '${name.substring(0, 6)}..' : name;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        shortName,
        style: GoogleFonts.montserrat(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLeftTitle(double value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        _formatCompactPrice(value),
        style: GoogleFonts.montserrat(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
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
