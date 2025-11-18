import 'package:supabase_flutter/supabase_flutter.dart';

enum TimeGranularity {
  minute,
  hour,
  day,
  week,
  month,
  year,
}

class UnifiedRevenueService {
  static final _client = Supabase.instance.client;
  static const double platformCommissionRate = 0.15; // 15% pour la plateforme
  static const double livreurRate = 0.85; // 85% pour le livreur

  /// Récupère le dashboard principal de la plateforme
  Future<Map<String, dynamic>> getPlatformDashboard() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisWeek = now.subtract(Duration(days: now.weekday - 1));
      final thisMonth = DateTime(now.year, now.month, 1);

      // Revenus aujourd'hui
      final todayRevenue = await _calculateRevenueForPeriod(today, now);
      
      // Revenus cette semaine
      final weekRevenue = await _calculateRevenueForPeriod(thisWeek, now);
      
      // Revenus ce mois
      final monthRevenue = await _calculateRevenueForPeriod(thisMonth, now);
      
      // Revenus totaux
      final totalRevenue = await _calculateTotalRevenue();
      
      // Missions totales
      final totalMissions = await _getTotalMissions();
      
      // Commission moyenne
      final avgCommission = await _getAverageCommission();

      return {
        'today_revenue': todayRevenue,
        'this_week_revenue': weekRevenue,
        'this_month_revenue': monthRevenue,
        'total_revenue': totalRevenue,
        'total_missions': totalMissions,
        'avg_commission': avgCommission,
        'this_month_missions': await _getMissionsForPeriod(thisMonth, now),
      };
    } catch (e) {
      throw Exception('Erreur lors du chargement du dashboard: $e');
    }
  }

  /// Récupère l'historique des revenus de la plateforme
  Future<List<Map<String, dynamic>>> getPlatformRevenueHistory({int limit = 50}) async {
    try {
      final missions = await _client
          .from('missions')
          .select('''
            id,
            prix,
            created_at,
            start_address,
            end_address,
            status
          ''')
          .eq('status', 'livrée')
          .order('created_at', ascending: false)
          .limit(limit);

      return missions.map((mission) {
        final originalAmount = (mission['prix'] as num?)?.toDouble() ?? 0;
        final commissionAmount = originalAmount * platformCommissionRate;

        return {
          'id': mission['id'],
          'amount': commissionAmount,
          'created_at': mission['created_at'],
          'mission': {
            'start_address': mission['start_address'],
            'end_address': mission['end_address'],
          },
          'metadata': {
            'original_amount': originalAmount,
            'commission_rate': platformCommissionRate,
          },
        };
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement de l\'historique: $e');
    }
  }

  /// Récupère les métriques de commission par livreur
  Future<List<Map<String, dynamic>>> getCommissionMetricsByLivreur({int limit = 20}) async {
    try {
      final result = await _client.rpc('get_livreur_commission_metrics', params: {
        'result_limit': limit,
      });

      if (result == null) return [];

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      // Fallback si la fonction RPC n'existe pas
      return await _getCommissionMetricsFallback(limit);
    }
  }

  /// Récupère les statistiques de revenus par période
  Future<List<Map<String, dynamic>>> getRevenueStatsByPeriod({
    required String periodType,
    int limit = 12,
  }) async {
    try {
      final now = DateTime.now();
      final stats = <Map<String, dynamic>>[];

      for (int i = 0; i < limit; i++) {
        DateTime periodStart;
        DateTime periodEnd;
        String periodLabel;

        if (periodType == 'monthly') {
          periodStart = DateTime(now.year, now.month - i, 1);
          periodEnd = DateTime(now.year, now.month - i + 1, 1);
          periodLabel = _getMonthName(periodStart.month);
        } else {
          // Weekly
          final weekStart = now.subtract(Duration(days: (i * 7) + now.weekday - 1));
          periodStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
          periodEnd = periodStart.add(const Duration(days: 7));
          periodLabel = 'Semaine ${i + 1}';
        }

        final revenue = await _calculateRevenueForPeriod(periodStart, periodEnd);
        final missions = await _getMissionsForPeriod(periodStart, periodEnd);

        stats.add({
          'period': periodLabel,
          'revenue': revenue,
          'missions_count': missions,
          'start_date': periodStart.toIso8601String(),
          'end_date': periodEnd.toIso8601String(),
        });
      }

      return stats.reversed.toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des statistiques: $e');
    }
  }

  /// Récupère le solde actuel de la plateforme
  Future<double> getPlatformBalance() async {
    try {
      return await _calculateTotalRevenue();
    } catch (e) {
      throw Exception('Erreur lors du chargement du solde: $e');
    }
  }

  /// Calcule les commissions pour une mission donnée
  static Map<String, double> calculateCommissionForMission(double missionPrice) {
    return {
      'platform_commission': missionPrice * platformCommissionRate,
      'livreur_amount': missionPrice * livreurRate,
      'total': missionPrice,
    };
  }

  /// Récupère les commissions par période
  Future<Map<String, dynamic>> getCommissionsByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final missions = await _client
          .from('missions')
          .select('prix, livreur_id, created_at')
          .eq('status', 'livrée')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      double totalPlatformCommission = 0;
      double totalLivreurAmount = 0;
      double totalRevenue = 0;

      for (final mission in missions) {
        final prix = (mission['prix'] as num?)?.toDouble() ?? 0;
        totalRevenue += prix;
        totalPlatformCommission += prix * platformCommissionRate;
        totalLivreurAmount += prix * livreurRate;
      }

      return {
        'total_missions': missions.length,
        'total_revenue': totalRevenue,
        'platform_commission': totalPlatformCommission,
        'livreur_total': totalLivreurAmount,
        'commission_rate': platformCommissionRate,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des commissions: $e');
    }
  }

  /// Récupère le top des livreurs par commissions générées
  Future<List<Map<String, dynamic>>> getTopLivreursByCommission({
    int limit = 10,
  }) async {
    try {
      // Récupérer tous les livreurs
      final livreurs = await _client
          .from('user_profiles')
          .select('id, fullname, phone')
          .eq('role', 'livreur');

      final livreurStats = <Map<String, dynamic>>[];

      for (final livreur in livreurs) {
        final missions = await _client
            .from('missions')
            .select('prix')
            .eq('livreur_id', livreur['id'])
            .eq('status', 'livrée');

        double totalGenerated = 0;
        double platformCommission = 0;
        double livreurEarnings = 0;

        for (final mission in missions) {
          final prix = (mission['prix'] as num?)?.toDouble() ?? 0;
          totalGenerated += prix;
          platformCommission += prix * platformCommissionRate;
          livreurEarnings += prix * livreurRate;
        }

        if (missions.isNotEmpty) {
          livreurStats.add({
            'livreur_id': livreur['id'],
            'fullname': livreur['fullname'],
            'phone': livreur['phone'],
            'total_missions': missions.length,
            'total_generated': totalGenerated,
            'platform_commission': platformCommission,
            'livreur_earnings': livreurEarnings,
            'avg_mission_value': totalGenerated / missions.length,
          });
        }
      }

      // Trier par commission générée pour la plateforme
      livreurStats.sort((a, b) => 
          (b['platform_commission'] as double).compareTo(a['platform_commission'] as double));

      return livreurStats.take(limit).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement du top livreurs: $e');
    }
  }

  /// Récupère les statistiques de commission par mois
  Future<List<Map<String, dynamic>>> getMonthlyCommissionStats({
    int monthsBack = 12,
  }) async {
    try {
      final now = DateTime.now();
      final stats = <Map<String, dynamic>>[];

      for (int i = 0; i < monthsBack; i++) {
        final monthStart = DateTime(now.year, now.month - i, 1);
        final monthEnd = DateTime(now.year, now.month - i + 1, 1);

        final commissions = await getCommissionsByPeriod(
          startDate: monthStart,
          endDate: monthEnd,
        );

        stats.add({
          'month': _getMonthName(monthStart.month),
          'year': monthStart.year,
          'date': monthStart.toIso8601String(),
          ...commissions,
        });
      }

      return stats.reversed.toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des stats mensuelles: $e');
    }
  }

  // Méthodes privées

  Future<double> _calculateRevenueForPeriod(DateTime start, DateTime end) async {
    final missions = await _client
        .from('missions')
        .select('prix')
        .eq('status', 'livrée')
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String());

    double total = 0;
    for (final mission in missions) {
      final prix = (mission['prix'] as num?)?.toDouble() ?? 0;
      total += prix * platformCommissionRate;
    }
    return total;
  }

  Future<double> _calculateTotalRevenue() async {
    final missions = await _client
        .from('missions')
        .select('prix')
        .eq('status', 'livrée');

    double total = 0;
    for (final mission in missions) {
      final prix = (mission['prix'] as num?)?.toDouble() ?? 0;
      total += prix * platformCommissionRate;
    }
    return total;
  }

  Future<int> _getTotalMissions() async {
    final result = await _client
        .from('missions')
        .select('id')
        .count();
    return result.count;
  }

  Future<int> _getMissionsForPeriod(DateTime start, DateTime end) async {
    final result = await _client
        .from('missions')
        .select('id')
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String())
        .count();
    return result.count;
  }

  Future<double> _getAverageCommission() async {
    final missions = await _client
        .from('missions')
        .select('prix')
        .eq('status', 'livrée');

    if (missions.isEmpty) return 0;

    double total = 0;
    for (final mission in missions) {
      final prix = (mission['prix'] as num?)?.toDouble() ?? 0;
      total += prix * platformCommissionRate;
    }
    return total / missions.length;
  }

  Future<List<Map<String, dynamic>>> _getCommissionMetricsFallback(int limit) async {
    // Récupérer les livreurs avec leurs missions
    final livreurs = await _client
        .from('user_profiles')
        .select('id, fullname')
        .eq('role', 'livreur')
        .limit(limit);

    final metrics = <Map<String, dynamic>>[];

    for (final livreur in livreurs) {
      final missions = await _client
          .from('missions')
          .select('prix')
          .eq('livreur_id', livreur['id'])
          .eq('status', 'livrée');

      double totalCommissions = 0;
      for (final mission in missions) {
        final prix = (mission['prix'] as num?)?.toDouble() ?? 0;
        totalCommissions += prix * platformCommissionRate;
      }

      if (missions.isNotEmpty) {
        metrics.add({
          'livreur_id': livreur['id'],
          'total_commissions': totalCommissions,
          'total_missions': missions.length,
          'avg_commission': totalCommissions / missions.length,
          'user_profile': {
            'fullname': livreur['fullname'],
          },
        });
      }
    }

    // Trier par commissions totales
    metrics.sort((a, b) => (b['total_commissions'] as double)
        .compareTo(a['total_commissions'] as double));

    return metrics;
  }

  /// Récupère l'évolution des revenus avec filtres granulaires
  Future<List<Map<String, dynamic>>> getRevenueEvolutionWithGranularFilters({
    required TimeGranularity granularity,
    required DateTime startDate,
    required DateTime endDate,
    int maxDataPoints = 100,
  }) async {
    try {
      final missions = await _client
          .from('missions')
          .select('prix, created_at')
          .eq('status', 'livrée')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: true);

      if (missions.isEmpty) return [];

      // Générer les intervalles de temps selon la granularité
      final intervals = _generateTimeIntervals(
        startDate, 
        endDate, 
        granularity, 
        maxDataPoints
      );

      final revenueData = <Map<String, dynamic>>[];

      for (int i = 0; i < intervals.length - 1; i++) {
        final intervalStart = intervals[i];
        final intervalEnd = intervals[i + 1];

        // Calculer les revenus pour cet intervalle
        double intervalRevenue = 0;
        int missionCount = 0;

        for (final mission in missions) {
          final missionDate = DateTime.parse(mission['created_at']);
          if (missionDate.isAfter(intervalStart) && 
              missionDate.isBefore(intervalEnd)) {
            final prix = (mission['prix'] as num?)?.toDouble() ?? 0;
            intervalRevenue += prix * platformCommissionRate;
            missionCount++;
          }
        }

        revenueData.add({
          'period_start': intervalStart.toIso8601String(),
          'period_end': intervalEnd.toIso8601String(),
          'period_label': _formatPeriodLabel(intervalStart, granularity),
          'revenue': intervalRevenue,
          'mission_count': missionCount,
          'avg_revenue_per_mission': missionCount > 0 ? intervalRevenue / missionCount : 0,
          'timestamp': intervalStart.millisecondsSinceEpoch,
        });
      }

      return revenueData;
    } catch (e) {
      throw Exception('Erreur lors du chargement de l\'évolution des revenus: $e');
    }
  }

  /// Génère les intervalles de temps selon la granularité
  List<DateTime> _generateTimeIntervals(
    DateTime start,
    DateTime end,
    TimeGranularity granularity,
    int maxDataPoints,
  ) {
    final intervals = <DateTime>[];
    DateTime current = start;

    // Calculer l'intervalle optimal pour ne pas dépasser maxDataPoints
    final totalDuration = end.difference(start);
    Duration stepDuration;

    switch (granularity) {
      case TimeGranularity.minute:
        stepDuration = Duration(
          minutes: (totalDuration.inMinutes / maxDataPoints).ceil().clamp(1, 60)
        );
        break;
      case TimeGranularity.hour:
        stepDuration = Duration(
          hours: (totalDuration.inHours / maxDataPoints).ceil().clamp(1, 24)
        );
        break;
      case TimeGranularity.day:
        stepDuration = Duration(
          days: (totalDuration.inDays / maxDataPoints).ceil().clamp(1, 31)
        );
        break;
      case TimeGranularity.week:
        stepDuration = Duration(
          days: (totalDuration.inDays / maxDataPoints * 7).ceil().clamp(7, 365)
        );
        break;
      case TimeGranularity.month:
        stepDuration = Duration(
          days: (totalDuration.inDays / maxDataPoints * 30).ceil().clamp(30, 365)
        );
        break;
      case TimeGranularity.year:
        stepDuration = Duration(
          days: (totalDuration.inDays / maxDataPoints * 365).ceil().clamp(365, 3650)
        );
        break;
    }

    while (current.isBefore(end)) {
      intervals.add(current);
      current = current.add(stepDuration);
    }
    intervals.add(end);

    return intervals;
  }

  /// Formate le label de période selon la granularité
  String _formatPeriodLabel(DateTime dateTime, TimeGranularity granularity) {
    switch (granularity) {
      case TimeGranularity.minute:
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      case TimeGranularity.hour:
        return '${dateTime.day}/${dateTime.month} ${dateTime.hour}h';
      case TimeGranularity.day:
        return '${dateTime.day}/${dateTime.month}';
      case TimeGranularity.week:
        final weekNumber = ((dateTime.dayOfYear - 1) / 7).floor() + 1;
        return 'S$weekNumber';
      case TimeGranularity.month:
        return _getMonthName(dateTime.month);
      case TimeGranularity.year:
        return dateTime.year.toString();
    }
  }

  /// Récupère les statistiques de revenus pour une période avec granularité
  Future<Map<String, dynamic>> getRevenueStatsForPeriod({
    required DateTime startDate,
    required DateTime endDate,
    required TimeGranularity granularity,
  }) async {
    try {
      final evolutionData = await getRevenueEvolutionWithGranularFilters(
        granularity: granularity,
        startDate: startDate,
        endDate: endDate,
      );

      if (evolutionData.isEmpty) {
        return {
          'total_revenue': 0.0,
          'total_missions': 0,
          'avg_revenue': 0.0,
          'peak_revenue': 0.0,
          'peak_period': null,
          'growth_rate': 0.0,
          'data_points': 0,
        };
      }

      double totalRevenue = 0;
      int totalMissions = 0;
      double peakRevenue = 0;
      String? peakPeriod;

      for (final dataPoint in evolutionData) {
        final revenue = dataPoint['revenue'] as double;
        final missions = dataPoint['mission_count'] as int;

        totalRevenue += revenue;
        totalMissions += missions;

        if (revenue > peakRevenue) {
          peakRevenue = revenue;
          peakPeriod = dataPoint['period_label'];
        }
      }

      // Calculer le taux de croissance
      double growthRate = 0.0;
      if (evolutionData.length >= 2) {
        final firstRevenue = evolutionData.first['revenue'] as double;
        final lastRevenue = evolutionData.last['revenue'] as double;
        if (firstRevenue > 0) {
          growthRate = ((lastRevenue - firstRevenue) / firstRevenue) * 100;
        }
      }

      return {
        'total_revenue': totalRevenue,
        'total_missions': totalMissions,
        'avg_revenue': totalMissions > 0 ? totalRevenue / totalMissions : 0.0,
        'peak_revenue': peakRevenue,
        'peak_period': peakPeriod,
        'growth_rate': growthRate,
        'data_points': evolutionData.length,
        'period_start': startDate.toIso8601String(),
        'period_end': endDate.toIso8601String(),
        'granularity': granularity.toString(),
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month];
  }
}

extension DateTimeExtension on DateTime {
  int get dayOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    return difference(firstDayOfYear).inDays + 1;
  }
}
