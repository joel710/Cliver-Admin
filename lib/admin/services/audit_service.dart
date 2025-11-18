import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class AuditService {
  static final _supabase = Supabase.instance.client;

  /// Enregistre une action dans les logs d'audit
  static Future<void> log({
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? details,
    String severity = 'info',
    String? customUserId,
  }) async {
    try {
      final userId = customUserId ?? _supabase.auth.currentUser?.id;
      
      // Récupérer les informations de contexte
      final context = await _getContextInfo();
      
      await _supabase.from('audit_logs').insert({
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'user_id': userId,
        'ip_address': context['ip_address'],
        'user_agent': context['user_agent'],
        'details': details ?? {},
        'severity': severity,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('Audit log créé: $action sur $entityType ($entityId)');
    } catch (e) {
      debugPrint('Erreur création audit log: $e');
    }
  }

  /// Actions utilisateur
  static Future<void> logUserAction(String action, String userId, 
      {Map<String, dynamic>? details, String severity = 'info'}) async {
    await log(
      action: action,
      entityType: 'user',
      entityId: userId,
      details: details,
      severity: severity,
    );
  }

  /// Actions mission
  static Future<void> logMissionAction(String action, String missionId,
      {Map<String, dynamic>? details, String severity = 'info'}) async {
    await log(
      action: action,
      entityType: 'mission',
      entityId: missionId,
      details: details,
      severity: severity,
    );
  }

  /// Actions système
  static Future<void> logSystemAction(String action, String systemId,
      {Map<String, dynamic>? details, String severity = 'info'}) async {
    await log(
      action: action,
      entityType: 'system',
      entityId: systemId,
      details: details,
      severity: severity,
    );
  }

  /// Actions de paiement
  static Future<void> logPaymentAction(String action, String paymentId,
      {Map<String, dynamic>? details, String severity = 'info'}) async {
    await log(
      action: action,
      entityType: 'payment',
      entityId: paymentId,
      details: details,
      severity: severity,
    );
  }

  /// Actions de signalement
  static Future<void> logReportAction(String action, String reportId,
      {Map<String, dynamic>? details, String severity = 'info'}) async {
    await log(
      action: action,
      entityType: 'report',
      entityId: reportId,
      details: details,
      severity: severity,
    );
  }

  // Méthodes spécialisées pour les actions courantes

  /// Connexion utilisateur
  static Future<void> logLogin(String userId, {bool isSuccess = true}) async {
    await logUserAction(
      isSuccess ? 'login' : 'login_failed',
      userId,
      details: {
        'success': isSuccess,
        'timestamp': DateTime.now().toIso8601String(),
      },
      severity: isSuccess ? 'info' : 'warning',
    );
  }

  /// Déconnexion utilisateur
  static Future<void> logLogout(String userId) async {
    await logUserAction(
      'logout',
      userId,
      details: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Création d'utilisateur
  static Future<void> logUserCreation(String userId, String role) async {
    await logUserAction(
      'create',
      userId,
      details: {
        'role': role,
        'registration_method': 'email',
      },
    );
  }

  /// Modification de profil
  static Future<void> logProfileUpdate(String userId, Map<String, dynamic> changes) async {
    await logUserAction(
      'update',
      userId,
      details: {
        'fields_updated': changes.keys.toList(),
        'changes': changes,
      },
    );
  }

  /// Blocage d'utilisateur
  static Future<void> logUserBlock(String blockedUserId, String reason, 
      {String? blockedByUserId}) async {
    await logUserAction(
      'block',
      blockedUserId,
      details: {
        'reason': reason,
        'blocked_by': blockedByUserId ?? _supabase.auth.currentUser?.id,
        'blocked_at': DateTime.now().toIso8601String(),
      },
      severity: 'warning',
    );
  }

  /// Déblocage d'utilisateur
  static Future<void> logUserUnblock(String unblockedUserId, 
      {String? unblockedByUserId}) async {
    await logUserAction(
      'unblock',
      unblockedUserId,
      details: {
        'unblocked_by': unblockedByUserId ?? _supabase.auth.currentUser?.id,
        'unblocked_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Création de mission
  static Future<void> logMissionCreation(String missionId, String clientId,
      Map<String, dynamic> missionDetails) async {
    await logMissionAction(
      'create',
      missionId,
      details: {
        'client_id': clientId,
        'pickup_address': missionDetails['pickup_address'],
        'delivery_address': missionDetails['delivery_address'],
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Attribution de mission
  static Future<void> logMissionAssignment(String missionId, String livreurId,
      String clientId) async {
    await logMissionAction(
      'assign',
      missionId,
      details: {
        'livreur_id': livreurId,
        'client_id': clientId,
        'assigned_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Finalisation de mission
  static Future<void> logMissionCompletion(String missionId, String livreurId,
      {bool isAutomatic = false}) async {
    await logMissionAction(
      'complete',
      missionId,
      details: {
        'livreur_id': livreurId,
        'completion_type': isAutomatic ? 'automatic' : 'manual',
        'completed_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Annulation de mission
  static Future<void> logMissionCancellation(String missionId, String reason,
      {String? cancelledBy}) async {
    await logMissionAction(
      'cancel',
      missionId,
      details: {
        'reason': reason,
        'cancelled_by': cancelledBy ?? _supabase.auth.currentUser?.id,
        'cancelled_at': DateTime.now().toIso8601String(),
      },
      severity: 'warning',
    );
  }

  /// Création de signalement
  static Future<void> logReportCreation(String reportId, String reportedUserId,
      String reporterUserId, String reason) async {
    await logReportAction(
      'report',
      reportId,
      details: {
        'reported_user_id': reportedUserId,
        'reporter_user_id': reporterUserId,
        'reason': reason,
        'reported_at': DateTime.now().toIso8601String(),
      },
      severity: 'warning',
    );
  }

  /// Résolution de signalement
  static Future<void> logReportResolution(String reportId, String resolution,
      {String? resolvedBy}) async {
    await logReportAction(
      'resolve_report',
      reportId,
      details: {
        'resolution': resolution,
        'resolved_by': resolvedBy ?? _supabase.auth.currentUser?.id,
        'resolved_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Paiement effectué
  static Future<void> logPayment(String paymentId, String missionId,
      double amount, String method) async {
    await logPaymentAction(
      'payment',
      paymentId,
      details: {
        'mission_id': missionId,
        'amount': amount,
        'method': method,
        'currency': 'FCFA',
        'paid_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Remboursement traité
  static Future<void> logRefund(String refundId, String originalPaymentId,
      double amount, String reason) async {
    await logPaymentAction(
      'refund',
      refundId,
      details: {
        'original_payment_id': originalPaymentId,
        'amount': amount,
        'reason': reason,
        'currency': 'FCFA',
        'refunded_at': DateTime.now().toIso8601String(),
      },
      severity: 'warning',
    );
  }

  /// Erreur système
  static Future<void> logSystemError(String errorId, String error,
      {String? stackTrace, Map<String, dynamic>? context}) async {
    await logSystemAction(
      'error',
      errorId,
      details: {
        'error_message': error,
        'stack_trace': stackTrace,
        'context': context,
        'occurred_at': DateTime.now().toIso8601String(),
      },
      severity: 'error',
    );
  }

  /// Mise à jour système
  static Future<void> logSystemUpdate(String updateId, String version,
      Map<String, dynamic> changes) async {
    await logSystemAction(
      'update',
      updateId,
      details: {
        'version': version,
        'changes': changes,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Sauvegarde système
  static Future<void> logSystemBackup(String backupId, String type,
      {bool isSuccess = true}) async {
    await logSystemAction(
      'backup',
      backupId,
      details: {
        'backup_type': type,
        'success': isSuccess,
        'backed_up_at': DateTime.now().toIso8601String(),
      },
      severity: isSuccess ? 'info' : 'error',
    );
  }

  /// Récupère les informations de contexte (IP, User Agent, etc.)
  static Future<Map<String, String?>> _getContextInfo() async {
    try {
      // Pour une application mobile, ces informations sont limitées
      return {
        'ip_address': await _getDeviceIP(),
        'user_agent': await _getUserAgent(),
      };
    } catch (e) {
      debugPrint('Erreur récupération contexte: $e');
      return {
        'ip_address': null,
        'user_agent': null,
      };
    }
  }

  /// Récupère l'adresse IP de l'appareil (approximative)
  static Future<String?> _getDeviceIP() async {
    try {
      // Pour une app mobile, on peut essayer de récupérer l'IP locale
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback && address.type == InternetAddressType.IPv4) {
            return address.address;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Récupère le User Agent de l'appareil
  static Future<String?> _getUserAgent() async {
    try {
      if (kIsWeb) {
        // Pour le web, on pourrait utiliser dart:html
        return 'Web Browser';
      } else if (Platform.isAndroid) {
        return 'Kolisa Admin Android App';
      } else if (Platform.isIOS) {
        return 'Kolisa Admin iOS App';
      } else {
        return 'Kolisa Admin Mobile App';
      }
    } catch (e) {
      return null;
    }
  }

  /// Nettoie les anciens logs (à appeler périodiquement)
  static Future<void> cleanupOldLogs({int daysToKeep = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      await _supabase
          .from('audit_logs')
          .delete()
          .lt('created_at', cutoffDate.toIso8601String());
      
      debugPrint('Nettoyage des logs antérieurs au ${cutoffDate.toIso8601String()}');
    } catch (e) {
      debugPrint('Erreur nettoyage logs: $e');
    }
  }

  /// Récupère les statistiques des logs
  static Future<Map<String, dynamic>> getLogStats() async {
    try {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final lastWeek = today.subtract(const Duration(days: 7));
      
      // Logs d'aujourd'hui
      final todayResponse = await _supabase
          .from('audit_logs')
          .select('id')
          .gte('created_at', DateTime(today.year, today.month, today.day).toIso8601String());
      final todayCount = todayResponse.length;
      
      // Logs d'hier
      final yesterdayResponse = await _supabase
          .from('audit_logs')
          .select('id')
          .gte('created_at', DateTime(yesterday.year, yesterday.month, yesterday.day).toIso8601String())
          .lt('created_at', DateTime(today.year, today.month, today.day).toIso8601String());
      final yesterdayCount = yesterdayResponse.length;
      
      // Logs de la semaine
      final weekResponse = await _supabase
          .from('audit_logs')
          .select('id')
          .gte('created_at', lastWeek.toIso8601String());
      final weekCount = weekResponse.length;
      
      // Logs par sévérité
      final severityStats = await _supabase
          .from('audit_logs')
          .select('severity')
          .gte('created_at', lastWeek.toIso8601String());
      
      final severityCounts = <String, int>{};
      for (final log in severityStats) {
        final severity = log['severity'] as String;
        severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
      }
      
      return {
        'today': todayCount,
        'yesterday': yesterdayCount,
        'week': weekCount,
        'severity_breakdown': severityCounts,
      };
    } catch (e) {
      debugPrint('Erreur stats logs: $e');
      return {};
    }
  }
}
