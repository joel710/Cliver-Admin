import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'audit_service.dart';

class AnalyticsService {
  static final _supabase = Supabase.instance.client;
  static SupabaseClient get supabase => _supabase;
  static Timer? _analyticsTimer;
  static const Duration _updateInterval = Duration(minutes: 15);

  /// Démarre le système d'analytics automatique
  static void startAnalytics() {
    debugPrint('Démarrage du système d\'analytics');
    
    _analyticsTimer?.cancel();
    _analyticsTimer = Timer.periodic(_updateInterval, (_) {
      _updateAnalytics();
    });
    
    // Mise à jour immédiate au démarrage
    _updateAnalytics();
  }

  /// Arrête le système d'analytics
  static void stopAnalytics() {
    _analyticsTimer?.cancel();
    _analyticsTimer = null;
    debugPrint('Système d\'analytics arrêté');
  }

  /// Met à jour toutes les métriques d'analytics
  static Future<void> _updateAnalytics() async {
    try {
      debugPrint('Mise à jour des analytics...');
      
      await _updateUserMetrics();
      await _updateMissionMetrics();
      await _updateRevenueMetrics();
      await _updatePerformanceMetrics();
      await _updateSystemMetrics();
      
    } catch (e) {
      debugPrint('Erreur mise à jour analytics: $e');
      await AuditService.logSystemError(
        'analytics_update_error',
        'Erreur dans la mise à jour des analytics: $e',
      );
    }
  }

  /// Métriques utilisateurs
  static Future<Map<String, dynamic>> getUserMetrics() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final lastWeek = now.subtract(const Duration(days: 7));
      final lastMonth = now.subtract(const Duration(days: 30));

      // Utilisateurs totaux
      final totalUsers = await _supabase
          .from('user_profiles')
          .select('id, role, created_at')
          .count();

      // Nouveaux utilisateurs aujourd'hui
      final newUsersToday = await _supabase
          .from('user_profiles')
          .select('id')
          .gte('created_at', today.toIso8601String())
          .count();

      // Nouveaux utilisateurs hier
      final newUsersYesterday = await _supabase
          .from('user_profiles')
          .select('id')
          .gte('created_at', yesterday.toIso8601String())
          .lt('created_at', today.toIso8601String())
          .count();

      // Utilisateurs actifs (ayant créé une mission ou accepté une mission dans les 7 derniers jours)
      final activeMissions = await _supabase
          .from('missions')
          .select('client_id, livreur_id')
          .gte('created_at', lastWeek.toIso8601String());

      final activeUserIds = <String>{};
      for (final mission in activeMissions) {
        if (mission['client_id'] != null) activeUserIds.add(mission['client_id']);
        if (mission['livreur_id'] != null) activeUserIds.add(mission['livreur_id']);
      }

      // Répartition par rôle
      final usersByRole = await _supabase
          .from('user_profiles')
          .select('role');

      final roleStats = <String, int>{};
      for (final user in usersByRole) {
        final role = user['role'] ?? 'unknown';
        roleStats[role] = (roleStats[role] ?? 0) + 1;
      }

      // Taux de croissance
      final growthRate = newUsersYesterday.count > 0 
          ? ((newUsersToday.count - newUsersYesterday.count) / newUsersYesterday.count) * 100
          : 0.0;

      return {
        'total_users': totalUsers.count,
        'new_users_today': newUsersToday.count,
        'new_users_yesterday': newUsersYesterday.count,
        'active_users_week': activeUserIds.length,
        'growth_rate': growthRate,
        'users_by_role': roleStats,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Erreur métriques utilisateurs: $e');
      return {};
    }
  }

  /// Métriques missions
  static Future<Map<String, dynamic>> getMissionMetrics() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final lastWeek = now.subtract(const Duration(days: 7));

      // Missions totales
      final totalMissions = await _supabase
          .from('missions')
          .select('id')
          .count();

      // Missions par statut
      final missionsByStatus = await _supabase
          .from('missions')
          .select('status');

      final statusStats = <String, int>{};
      for (final mission in missionsByStatus) {
        final status = mission['status'] ?? 'unknown';
        statusStats[status] = (statusStats[status] ?? 0) + 1;
      }

      // Missions aujourd'hui
      final missionsToday = await _supabase
          .from('missions')
          .select('id, status')
          .gte('created_at', today.toIso8601String());

      // Missions hier
      final missionsYesterday = await _supabase
          .from('missions')
          .select('id, status')
          .gte('created_at', yesterday.toIso8601String())
          .lt('created_at', today.toIso8601String());

      // Taux de succès (missions livrées / missions totales)
      final completedMissions = statusStats['livrée'] ?? 0;
      final successRate = totalMissions.count > 0 
          ? (completedMissions / totalMissions.count) * 100
          : 0.0;

      // Temps moyen de livraison
      final completedMissionsWithTime = await _supabase
          .from('missions')
          .select('created_at, delivery_confirmed_at')
          .eq('status', 'livrée')
          .gte('created_at', lastWeek.toIso8601String())
          .not('delivery_confirmed_at', 'is', null)
          .limit(100);

      double avgDeliveryTime = 0.0;
      if (completedMissionsWithTime.isNotEmpty) {
        double totalTime = 0.0;
        int validMissions = 0;
        
        for (final mission in completedMissionsWithTime) {
          try {
            final created = DateTime.parse(mission['created_at']);
            final completed = DateTime.parse(mission['delivery_confirmed_at']);
            totalTime += completed.difference(created).inMinutes.toDouble();
            validMissions++;
          } catch (e) {
            // Ignorer les missions avec des dates invalides
          }
        }
        
        if (validMissions > 0) {
          avgDeliveryTime = totalTime / validMissions;
        }
      }

      return {
        'total_missions': totalMissions.count,
        'missions_today': missionsToday.length,
        'missions_yesterday': missionsYesterday.length,
        'missions_by_status': statusStats,
        'success_rate': successRate,
        'avg_delivery_time_minutes': avgDeliveryTime,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Erreur métriques missions: $e');
      return {};
    }
  }

  /// Métriques revenus
  static Future<Map<String, dynamic>> getRevenueMetrics() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisMonth = DateTime(now.year, now.month, 1);
      final lastMonth = DateTime(now.year, now.month - 1, 1);

      // Revenus totaux
      final allTransactions = await _supabase
          .from('transactions')
          .select('amount, type, status, created_at')
          .eq('status', 'completed');

      double totalRevenue = 0.0;
      double revenueToday = 0.0;
      double revenueThisMonth = 0.0;
      double revenueLastMonth = 0.0;

      for (final transaction in allTransactions) {
        final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
        final createdAt = DateTime.parse(transaction['created_at']);
        
        totalRevenue += amount;
        
        if (createdAt.isAfter(today)) {
          revenueToday += amount;
        }
        
        if (createdAt.isAfter(thisMonth)) {
          revenueThisMonth += amount;
        }
        
        if (createdAt.isAfter(lastMonth) && createdAt.isBefore(thisMonth)) {
          revenueLastMonth += amount;
        }
      }

      // Revenus par type de transaction
      final revenueByType = <String, double>{};
      for (final transaction in allTransactions) {
        final type = transaction['type'] ?? 'unknown';
        final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
        revenueByType[type] = (revenueByType[type] ?? 0.0) + amount;
      }

      // Taux de croissance mensuel
      final monthlyGrowthRate = revenueLastMonth > 0 
          ? ((revenueThisMonth - revenueLastMonth) / revenueLastMonth) * 100
          : 0.0;

      return {
        'total_revenue': totalRevenue,
        'revenue_today': revenueToday,
        'revenue_this_month': revenueThisMonth,
        'revenue_last_month': revenueLastMonth,
        'monthly_growth_rate': monthlyGrowthRate,
        'revenue_by_type': revenueByType,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Erreur métriques revenus: $e');
      return {};
    }
  }

  /// Métriques de performance système
  static Future<Map<String, dynamic>> getSystemMetrics() async {
    try {
      final now = DateTime.now();
      final lastHour = now.subtract(const Duration(hours: 1));
      final last24Hours = now.subtract(const Duration(hours: 24));

      // Logs d'erreur
      final errorLogs = await _supabase
          .from('audit_logs')
          .select('severity, created_at')
          .inFilter('severity', ['error', 'critical'])
          .gte('created_at', last24Hours.toIso8601String());

      final errorsByHour = <int, int>{};
      for (final log in errorLogs) {
        final hour = DateTime.parse(log['created_at']).hour;
        errorsByHour[hour] = (errorsByHour[hour] ?? 0) + 1;
      }

      // Alertes actives
      final activeAlerts = await _supabase
          .from('admin_alerts')
          .select('severity')
          .eq('is_read', false);

      final alertsBySeverity = <String, int>{};
      for (final alert in activeAlerts) {
        final severity = alert['severity'] ?? 'info';
        alertsBySeverity[severity] = (alertsBySeverity[severity] ?? 0) + 1;
      }

      // Utilisateurs bloqués
      final blockedUsers = await _supabase
          .from('user_blocks')
          .select('id')
          .count();

      // Signalements en attente
      final pendingReports = await _supabase
          .from('user_reports')
          .select('id')
          .eq('status', 'open')
          .count();

      return {
        'errors_last_24h': errorLogs.length,
        'errors_by_hour': errorsByHour,
        'active_alerts': activeAlerts.length,
        'alerts_by_severity': alertsBySeverity,
        'blocked_users': blockedUsers.count,
        'pending_reports': pendingReports.count,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Erreur métriques système: $e');
      return {};
    }
  }

  /// Met à jour les métriques utilisateurs
  static Future<void> _updateUserMetrics() async {
    final metrics = await getUserMetrics();
    await AuditService.logSystemAction(
      'analytics_update',
      'user_metrics',
      details: {'metrics_count': metrics.length},
    );
  }

  /// Met à jour les métriques missions
  static Future<void> _updateMissionMetrics() async {
    final metrics = await getMissionMetrics();
    await AuditService.logSystemAction(
      'analytics_update',
      'mission_metrics',
      details: {'metrics_count': metrics.length},
    );
  }

  /// Met à jour les métriques revenus
  static Future<void> _updateRevenueMetrics() async {
    final metrics = await getRevenueMetrics();
    await AuditService.logSystemAction(
      'analytics_update',
      'revenue_metrics',
      details: {'metrics_count': metrics.length},
    );
  }

  /// Met à jour les métriques de performance
  static Future<void> _updatePerformanceMetrics() async {
    final metrics = await getSystemMetrics();
    await AuditService.logSystemAction(
      'analytics_update',
      'system_metrics',
      details: {'metrics_count': metrics.length},
    );
  }

  /// Met à jour les métriques système
  static Future<void> _updateSystemMetrics() async {
    // Calculer l'uptime de l'application
    final uptime = DateTime.now().difference(DateTime.now().subtract(const Duration(hours: 1)));
    
    await AuditService.logSystemAction(
      'system_health_check',
      'uptime',
      details: {
        'uptime_minutes': uptime.inMinutes,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Récupère un rapport complet d'analytics
  static Future<Map<String, dynamic>> getFullAnalyticsReport() async {
    try {
      final userMetrics = await getUserMetrics();
      final missionMetrics = await getMissionMetrics();
      final revenueMetrics = await getRevenueMetrics();
      final systemMetrics = await getSystemMetrics();

      return {
        'users': userMetrics,
        'missions': missionMetrics,
        'revenue': revenueMetrics,
        'system': systemMetrics,
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Erreur rapport analytics complet: $e');
      return {};
    }
  }

  /// Exporte les analytics vers un format JSON
  static Future<String> exportAnalytics({DateTime? startDate, DateTime? endDate}) async {
    try {
      final report = await getFullAnalyticsReport();
      
      final exportData = {
        'export_info': {
          'generated_at': DateTime.now().toIso8601String(),
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'version': '1.0',
        },
        'analytics': report,
      };

      await AuditService.logSystemAction(
        'analytics_export',
        'full_report',
        details: {
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
      );

      return exportData.toString();
    } catch (e) {
      debugPrint('Erreur export analytics: $e');
      return '{}';
    }
  }
}
