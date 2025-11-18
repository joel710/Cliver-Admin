import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'audit_service.dart';

class AdminAlertsService {
  static final _supabase = Supabase.instance.client;
  static Timer? _alertTimer;
  static const Duration _checkInterval = Duration(minutes: 5);

  /// Démarre le système d'alertes automatiques
  static void startAlertSystem() {
    debugPrint('Démarrage du système d\'alertes admin');
    
    _alertTimer?.cancel();
    _alertTimer = Timer.periodic(_checkInterval, (_) {
      _checkAndSendAlerts();
    });
    
    // Vérification immédiate au démarrage
    _checkAndSendAlerts();
  }

  /// Arrête le système d'alertes
  static void stopAlertSystem() {
    _alertTimer?.cancel();
    _alertTimer = null;
    debugPrint('Système d\'alertes admin arrêté');
  }

  /// Vérifie toutes les conditions d'alerte et envoie les notifications
  static Future<void> _checkAndSendAlerts() async {
    try {
      debugPrint('Vérification des alertes admin...');
      
      // Récupérer tous les admins
      final admins = await _getAdmins();
      if (admins.isEmpty) return;

      // Vérifier chaque type d'alerte
      await _checkPendingReports(admins);
      await _checkSuspiciousMissions(admins);
      await _checkBlockedUsers(admins);
      await _checkSystemErrors(admins);
      await _checkHighVolumeActivity(admins);
      await _checkLowSuccessRate(admins);
      await _checkUnverifiedUsers(admins);
      await _checkPaymentIssues(admins);
      
    } catch (e) {
      debugPrint('Erreur vérification alertes: $e');
      await AuditService.logSystemError(
        'alert_system_error',
        'Erreur dans le système d\'alertes: $e',
      );
    }
  }

  /// Récupère la liste des administrateurs
  static Future<List<Map<String, dynamic>>> _getAdmins() async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('id, fullname, fcm_token')
          .eq('role', 'admin');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur récupération admins: $e');
      return [];
    }
  }

  /// Alerte: Signalements en attente
  static Future<void> _checkPendingReports(List<Map<String, dynamic>> admins) async {
    try {
      final pendingReports = await _supabase
          .from('user_reports')
          .select('id')
          .eq('status', 'pending')
          .count();

      if (pendingReports.count > 5) {
        await _sendAlert(
          admins,
          'Signalements en attente',
          '${pendingReports.count} signalements nécessitent votre attention',
          'high_priority_reports',
          {'count': pendingReports.count},
          severity: 'warning',
        );
      }
    } catch (e) {
      debugPrint('Erreur vérification signalements: $e');
    }
  }

  /// Alerte: Missions suspectes
  static Future<void> _checkSuspiciousMissions(List<Map<String, dynamic>> admins) async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      
      // Missions annulées en masse
      final cancelledMissions = await _supabase
          .from('missions')
          .select('id')
          .eq('status', 'annulée')
          .gte('updated_at', oneHourAgo.toIso8601String())
          .count();

      if (cancelledMissions.count > 10) {
        await _sendAlert(
          admins,
          'Pic d\'annulations',
          '${cancelledMissions.count} missions annulées dans la dernière heure',
          'mass_cancellations',
          {'count': cancelledMissions.count, 'timeframe': '1 hour'},
          severity: 'warning',
        );
      }

      // Missions bloquées depuis longtemps
      final stuckMissions = await _supabase
          .from('missions')
          .select('id')
          .inFilter('status', ['en_attente', 'attribuée'])
          .lt('created_at', now.subtract(const Duration(hours: 24)).toIso8601String())
          .count();

      if (stuckMissions.count > 5) {
        await _sendAlert(
          admins,
          'Missions bloquées',
          '${stuckMissions.count} missions en attente depuis plus de 24h',
          'stuck_missions',
          {'count': stuckMissions.count},
          severity: 'warning',
        );
      }
    } catch (e) {
      debugPrint('Erreur vérification missions suspectes: $e');
    }
  }

  /// Alerte: Utilisateurs bloqués en masse
  static Future<void> _checkBlockedUsers(List<Map<String, dynamic>> admins) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final blockedToday = await _supabase
          .from('user_blocks')
          .select('id')
          .gte('created_at', startOfDay.toIso8601String())
          .count();

      if (blockedToday.count > 20) {
        await _sendAlert(
          admins,
          'Blocages massifs',
          '${blockedToday.count} utilisateurs bloqués aujourd\'hui',
          'mass_blocks',
          {'count': blockedToday.count, 'date': startOfDay.toIso8601String()},
          severity: 'critical',
        );
      }
    } catch (e) {
      debugPrint('Erreur vérification blocages: $e');
    }
  }

  /// Alerte: Erreurs système
  static Future<void> _checkSystemErrors(List<Map<String, dynamic>> admins) async {
    try {
      final lastHour = DateTime.now().subtract(const Duration(hours: 1));
      
      final errorLogs = await _supabase
          .from('audit_logs')
          .select('id')
          .inFilter('severity', ['error', 'critical'])
          .gte('created_at', lastHour.toIso8601String())
          .count();

      if (errorLogs.count > 10) {
        await _sendAlert(
          admins,
          'Erreurs système',
          '${errorLogs.count} erreurs détectées dans la dernière heure',
          'system_errors',
          {'count': errorLogs.count},
          severity: 'error',
        );
      }
    } catch (e) {
      debugPrint('Erreur vérification erreurs système: $e');
    }
  }

  /// Alerte: Activité anormalement élevée
  static Future<void> _checkHighVolumeActivity(List<Map<String, dynamic>> admins) async {
    try {
      final lastHour = DateTime.now().subtract(const Duration(hours: 1));
      
      // Nouvelles inscriptions
      final newUsers = await _supabase
          .from('user_profiles')
          .select('id')
          .gte('created_at', lastHour.toIso8601String())
          .count();

      if (newUsers.count > 50) {
        await _sendAlert(
          admins,
          'Pic d\'inscriptions',
          '${newUsers.count} nouvelles inscriptions dans la dernière heure',
          'high_registrations',
          {'count': newUsers.count},
          severity: 'info',
        );
      }

      // Nouvelles missions
      final newMissions = await _supabase
          .from('missions')
          .select('id')
          .gte('created_at', lastHour.toIso8601String())
          .count();

      if (newMissions.count > 100) {
        await _sendAlert(
          admins,
          'Pic de missions',
          '${newMissions.count} nouvelles missions dans la dernière heure',
          'high_mission_volume',
          {'count': newMissions.count},
          severity: 'info',
        );
      }
    } catch (e) {
      debugPrint('Erreur vérification activité élevée: $e');
    }
  }

  /// Alerte: Taux de succès faible
  static Future<void> _checkLowSuccessRate(List<Map<String, dynamic>> admins) async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      
      // Missions des dernières 24h
      final allMissions = await _supabase
          .from('missions')
          .select('id, status')
          .gte('created_at', yesterday.toIso8601String());

      if (allMissions.length < 10) return; // Pas assez de données

      final completedMissions = allMissions
          .where((m) => m['status'] == 'livrée')
          .length;
      
      final successRate = (completedMissions / allMissions.length) * 100;

      if (successRate < 70) {
        await _sendAlert(
          admins,
          'Taux de succès faible',
          'Taux de livraison: ${successRate.toStringAsFixed(1)}% ($completedMissions/${allMissions.length})',
          'low_success_rate',
          {
            'success_rate': successRate,
            'completed': completedMissions,
            'total': allMissions.length,
          },
          severity: 'warning',
        );
      }
    } catch (e) {
      debugPrint('Erreur vérification taux de succès: $e');
    }
  }

  /// Alerte: Utilisateurs non vérifiés
  static Future<void> _checkUnverifiedUsers(List<Map<String, dynamic>> admins) async {
    try {
      final unverifiedLivreurs = await _supabase
          .from('user_profiles')
          .select('id')
          .eq('role', 'livreur')
          .eq('is_verified', false)
          .count();

      if (unverifiedLivreurs.count > 10) {
        await _sendAlert(
          admins,
          'Livreurs non vérifiés',
          '${unverifiedLivreurs.count} livreurs en attente de vérification',
          'unverified_livreurs',
          {'count': unverifiedLivreurs.count},
          severity: 'info',
        );
      }
    } catch (e) {
      debugPrint('Erreur vérification utilisateurs non vérifiés: $e');
    }
  }

  /// Alerte: Problèmes de paiement
  static Future<void> _checkPaymentIssues(List<Map<String, dynamic>> admins) async {
    try {
      // Missions livrées sans paiement depuis plus de 24h
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      
      final unpaidMissions = await _supabase
          .from('missions')
          .select('id')
          .eq('status', 'livrée')
          .eq('is_paid', false)
          .lt('delivered_at', yesterday.toIso8601String())
          .count();

      if (unpaidMissions.count > 5) {
        await _sendAlert(
          admins,
          'Paiements en retard',
          '${unpaidMissions.count} missions livrées non payées depuis plus de 24h',
          'unpaid_missions',
          {'count': unpaidMissions.count},
          severity: 'warning',
        );
      }
    } catch (e) {
      debugPrint('Erreur vérification paiements: $e');
    }
  }

  /// Envoie une alerte à tous les administrateurs
  static Future<void> _sendAlert(
    List<Map<String, dynamic>> admins,
    String title,
    String message,
    String alertType,
    Map<String, dynamic> data, {
    String severity = 'info',
  }) async {
    try {
      // Vérifier si cette alerte a déjà été envoyée récemment
      final recentAlert = await _supabase
          .from('admin_alerts')
          .select('id')
          .eq('alert_type', alertType)
          .gte('created_at', DateTime.now().subtract(const Duration(hours: 1)).toIso8601String())
          .maybeSingle();

      if (recentAlert != null) {
        debugPrint('Alerte $alertType déjà envoyée récemment');
        return;
      }

      // Créer l'alerte en base
      final alertResponse = await _supabase
          .from('admin_alerts')
          .insert({
            'alert_type': alertType,
            'title': title,
            'message': message,
            'severity': severity,
            'data': data,
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final alertId = alertResponse['id'];

      // Envoyer notification à chaque admin
      for (final admin in admins) {
        await _sendNotificationToAdmin(admin, title, message, alertType, data);
        
        // Marquer l'alerte comme envoyée à cet admin
        await _supabase.from('admin_alert_recipients').insert({
          'alert_id': alertId,
          'admin_id': admin['id'],
          'sent_at': DateTime.now().toIso8601String(),
        });
      }

      // Log de l'alerte
      await AuditService.logSystemAction(
        'admin_alert',
        alertId,
        details: {
          'alert_type': alertType,
          'title': title,
          'severity': severity,
          'recipients_count': admins.length,
        },
        severity: severity,
      );

      debugPrint('Alerte envoyée: $title');
    } catch (e) {
      debugPrint('Erreur envoi alerte: $e');
    }
  }

  /// Envoie une notification à un administrateur spécifique
  static Future<void> _sendNotificationToAdmin(
    Map<String, dynamic> admin,
    String title,
    String message,
    String alertType,
    Map<String, dynamic> data,
  ) async {
    try {
      // Utiliser le service de notifications existant
      await _supabase.functions.invoke('send-push-notification', body: {
        'user_id': admin['id'],
        'title': '🚨 $title',
        'body': message,
        'type': 'admin_alert',
        'data': {
          'alert_type': alertType,
          'severity': data['severity'] ?? 'info',
          ...data,
        },
      });
    } catch (e) {
      debugPrint('Erreur envoi notification admin ${admin['id']}: $e');
    }
  }

  /// Marque une alerte comme lue
  static Future<void> markAlertAsRead(String alertId) async {
    try {
      await _supabase
          .from('admin_alerts')
          .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('id', alertId);
    } catch (e) {
      debugPrint('Erreur marquage alerte lue: $e');
    }
  }

  /// Récupère les alertes non lues pour un admin
  static Future<List<Map<String, dynamic>>> getUnreadAlerts(String adminId) async {
    try {
      final response = await _supabase
          .from('admin_alerts')
          .select('*')
          .eq('is_read', false)
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur récupération alertes: $e');
      return [];
    }
  }

  /// Récupère les statistiques des alertes
  static Future<Map<String, dynamic>> getAlertStats() async {
    try {
      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      
      final alerts = await _supabase
          .from('admin_alerts')
          .select('severity, created_at')
          .gte('created_at', lastWeek.toIso8601String());

      final stats = <String, int>{};
      for (final alert in alerts) {
        final severity = alert['severity'] as String;
        stats[severity] = (stats[severity] ?? 0) + 1;
      }

      final unreadCount = await _supabase
          .from('admin_alerts')
          .select('id')
          .eq('is_read', false)
          .count();

      return {
        'total_last_week': alerts.length,
        'unread': unreadCount.count,
        'by_severity': stats,
      };
    } catch (e) {
      debugPrint('Erreur stats alertes: $e');
      return {};
    }
  }

  /// Nettoie les anciennes alertes
  static Future<void> cleanupOldAlerts({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      await _supabase
          .from('admin_alerts')
          .delete()
          .lt('created_at', cutoffDate.toIso8601String());
      
      debugPrint('Nettoyage alertes antérieures au ${cutoffDate.toIso8601String()}');
    } catch (e) {
      debugPrint('Erreur nettoyage alertes: $e');
    }
  }
}
