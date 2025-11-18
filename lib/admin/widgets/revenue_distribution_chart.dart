import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/delivery_price_utils.dart';

class RevenueDistributionChart extends StatelessWidget {
  final Map<String, dynamic> dashboardData;
  final double height;

  const RevenueDistributionChart({
    super.key,
    required this.dashboardData,
    this.height = 250,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalRevenue = (dashboardData['total_revenue'] as num?)?.toDouble() ?? 0.0;

    if (totalRevenue <= 0) {
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
                Icons.pie_chart_outline_rounded,
                size: 48,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun revenu à afficher',
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
                Icons.pie_chart_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Répartition des Revenus',
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
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    _buildPieChartData(colorScheme),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildLegend(colorScheme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PieChartData _buildPieChartData(ColorScheme colorScheme) {
    final sections = _generatePieSections(colorScheme);

    return PieChartData(
      sections: sections,
      centerSpaceRadius: 40,
      sectionsSpace: 2,
      pieTouchData: PieTouchData(
        enabled: true,
        touchCallback: (FlTouchEvent event, pieTouchResponse) {
          // Gestion des interactions si nécessaire
        },
      ),
    );
  }

  List<PieChartSectionData> _generatePieSections(ColorScheme colorScheme) {
    final todayRevenue = (dashboardData['today_revenue'] as num?)?.toDouble() ?? 0.0;
    final weekRevenue = (dashboardData['this_week_revenue'] as num?)?.toDouble() ?? 0.0;
    final monthRevenue = (dashboardData['this_month_revenue'] as num?)?.toDouble() ?? 0.0;
    final totalRevenue = (dashboardData['total_revenue'] as num?)?.toDouble() ?? 0.0;
    
    // Calculer les revenus par période
    final todayPercent = totalRevenue > 0 ? (todayRevenue / totalRevenue) * 100 : 0;
    final weekPercent = totalRevenue > 0 ? ((weekRevenue - todayRevenue) / totalRevenue) * 100 : 0;
    final monthPercent = totalRevenue > 0 ? ((monthRevenue - weekRevenue) / totalRevenue) * 100 : 0;
    final olderPercent = totalRevenue > 0 ? ((totalRevenue - monthRevenue) / totalRevenue) * 100 : 0;

    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.grey,
    ];

    final data = [
      {'label': 'Aujourd\'hui', 'value': todayRevenue, 'percent': todayPercent},
      {'label': 'Cette semaine', 'value': weekRevenue - todayRevenue, 'percent': weekPercent},
      {'label': 'Ce mois', 'value': monthRevenue - weekRevenue, 'percent': monthPercent},
      {'label': 'Plus ancien', 'value': totalRevenue - monthRevenue, 'percent': olderPercent},
    ];

    return data.asMap().entries.where((entry) => (entry.value['value'] as double?) != null && (entry.value['value'] as double) > 0).map((entry) {
      final index = entry.key;
      final item = entry.value;
      final percent = item['percent'] as double;
      
      return PieChartSectionData(
        color: colors[index],
        value: percent,
        title: '${percent.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }

  Widget _buildLegend(ColorScheme colorScheme) {
    final todayRevenue = (dashboardData['today_revenue'] as num?)?.toDouble() ?? 0.0;
    final weekRevenue = (dashboardData['this_week_revenue'] as num?)?.toDouble() ?? 0.0;
    final monthRevenue = (dashboardData['this_month_revenue'] as num?)?.toDouble() ?? 0.0;
    final totalRevenue = (dashboardData['total_revenue'] as num?)?.toDouble() ?? 0.0;

    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.grey,
    ];

    final legendItems = [
      {'label': 'Aujourd\'hui', 'value': todayRevenue, 'color': colors[0]},
      {'label': 'Cette semaine', 'value': weekRevenue - todayRevenue, 'color': colors[1]},
      {'label': 'Ce mois', 'value': monthRevenue - weekRevenue, 'color': colors[2]},
      {'label': 'Plus ancien', 'value': totalRevenue - monthRevenue, 'color': colors[3]},
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: legendItems.where((item) => (item['value'] as double) > 0).map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item['color'] as Color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['label'] as String,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      DeliveryPriceUtils.formatPrice(item['value'] as double),
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
