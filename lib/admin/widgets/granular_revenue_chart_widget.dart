import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/unified_revenue_service.dart';
import '../../core/utils/delivery_price_utils.dart';

class GranularRevenueChartWidget extends StatefulWidget {
  final double height;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const GranularRevenueChartWidget({
    super.key,
    this.height = 400,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<GranularRevenueChartWidget> createState() => _GranularRevenueChartWidgetState();
}

class _GranularRevenueChartWidgetState extends State<GranularRevenueChartWidget> {
  final UnifiedRevenueService _revenueService = UnifiedRevenueService();
  
  TimeGranularity _selectedGranularity = TimeGranularity.day;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  List<Map<String, dynamic>> _revenueData = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialStartDate != null) {
      _startDate = widget.initialStartDate!;
    }
    if (widget.initialEndDate != null) {
      _endDate = widget.initialEndDate!;
    }
    _loadRevenueData();
  }

  Future<void> _loadRevenueData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _revenueService.getRevenueEvolutionWithGranularFilters(
          granularity: _selectedGranularity,
          startDate: _startDate,
          endDate: _endDate,
        ),
        _revenueService.getRevenueStatsForPeriod(
          startDate: _startDate,
          endDate: _endDate,
          granularity: _selectedGranularity,
        ),
      ]);

      if (mounted) {
        setState(() {
          _revenueData = results[0] as List<Map<String, dynamic>>;
          _stats = results[1] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onGranularityChanged(TimeGranularity? granularity) {
    if (granularity != null && granularity != _selectedGranularity) {
      setState(() {
        _selectedGranularity = granularity;
      });
      _loadRevenueData();
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFFF7B31),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadRevenueData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: widget.height,
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
          // En-tête avec contrôles
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Iconsax.chart_21,
                      color: colorScheme.onSurface,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Évolution des Revenus',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _loadRevenueData,
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Contrôles de filtres
                Row(
                  children: [
                    // Sélecteur de granularité
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TimeGranularity>(
                          value: _selectedGranularity,
                          onChanged: _onGranularityChanged,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: colorScheme.onSurface,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: TimeGranularity.minute,
                              child: Text('Minutes'),
                            ),
                            DropdownMenuItem(
                              value: TimeGranularity.hour,
                              child: Text('Heures'),
                            ),
                            DropdownMenuItem(
                              value: TimeGranularity.day,
                              child: Text('Jours'),
                            ),
                            DropdownMenuItem(
                              value: TimeGranularity.week,
                              child: Text('Semaines'),
                            ),
                            DropdownMenuItem(
                              value: TimeGranularity.month,
                              child: Text('Mois'),
                            ),
                            DropdownMenuItem(
                              value: TimeGranularity.year,
                              child: Text('Années'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Sélecteur de période
                    InkWell(
                      onTap: _selectDateRange,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.calendar,
                              size: 16,
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_startDate.day}/${_startDate.month} - ${_endDate.day}/${_endDate.month}',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: colorScheme.onSurface,
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
          ),

          // Statistiques rapides
          if (!_isLoading && _stats.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildStatChip(
                    'Total',
                    DeliveryPriceUtils.formatPrice(_stats['total_revenue'] ?? 0),
                    colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    'Pic',
                    DeliveryPriceUtils.formatPrice(_stats['peak_revenue'] ?? 0),
                    colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    'Croissance',
                    '${(_stats['growth_rate'] ?? 0).toStringAsFixed(1)}%',
                    (_stats['growth_rate'] ?? 0) >= 0 ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Graphique
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildChart(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 9,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: const Color(0xFFFF7B31),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.warning_2,
              color: colorScheme.error,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Erreur de chargement',
              style: GoogleFonts.montserrat(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _error!,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_revenueData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.chart,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune donnée disponible',
              style: GoogleFonts.montserrat(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    final spots = _revenueData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final revenue = (data['revenue'] as num).toDouble();
      return FlSpot(index.toDouble(), revenue);
    }).toList();

    final maxY = spots.isEmpty ? 100.0 : spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final minY = spots.isEmpty ? 0.0 : spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: colorScheme.outline.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (_revenueData.length / 6).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _revenueData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _revenueData[index]['period_label'] ?? '',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) {
                return Text(
                  DeliveryPriceUtils.formatPrice(value),
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (_revenueData.length - 1).toDouble(),
        minY: minY * 0.9,
        maxY: maxY * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF7B31),
                const Color(0xFFFF7B31).withValues(alpha: 0.7),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFFFF7B31),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF7B31).withValues(alpha: 0.3),
                  const Color(0xFFFF7B31).withValues(alpha: 0.1),
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
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < _revenueData.length) {
                  final data = _revenueData[index];
                  return LineTooltipItem(
                    '${data['period_label']}\n${DeliveryPriceUtils.formatPrice(spot.y)}\n${data['mission_count']} missions',
                    GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
