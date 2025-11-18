import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:io';
import 'audit_service.dart';

class CrashReportingService {
  static final _supabase = Supabase.instance.client;
  static Timer? _crashMonitorTimer;
  static const Duration _monitorInterval = Duration(minutes: 5);
  static final List<CrashReport> _pendingReports = [];

  /// Démarre le système de crash reporting
  static void startCrashReporting() {
    debugPrint('Démarrage du système de crash reporting');
    
    // Configuration du gestionnaire d'erreurs Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // Configuration du gestionnaire d'erreurs Dart
    PlatformDispatcher.instance.onError = (error, stack) {
      _handleDartError(error, stack);
      return true;
    };

    // Démarrage du monitoring périodique
    _crashMonitorTimer?.cancel();
    _crashMonitorTimer = Timer.periodic(_monitorInterval, (_) {
      _processPendingReports();
    });

    debugPrint('Système de crash reporting démarré');
  }

  /// Arrête le système de crash reporting
  static void stopCrashReporting() {
    _crashMonitorTimer?.cancel();
    _crashMonitorTimer = null;
    debugPrint('Système de crash reporting arrêté');
  }

  /// Gère les erreurs Flutter
  static void _handleFlutterError(FlutterErrorDetails details) {
    debugPrint('Erreur Flutter détectée: ${details.exception}');
    
    final crashReport = CrashReport(
      type: 'flutter_error',
      error: details.exception.toString(),
      stackTrace: details.stack?.toString(),
      timestamp: DateTime.now(),
      context: details.context?.toString(),
      library: details.library,
      informationCollector: details.informationCollector?.call().toString(),
    );

    _recordCrash(crashReport);
  }

  /// Gère les erreurs Dart
  static void _handleDartError(Object error, StackTrace? stackTrace) {
    debugPrint('Erreur Dart détectée: $error');
    
    final crashReport = CrashReport(
      type: 'dart_error',
      error: error.toString(),
      stackTrace: stackTrace?.toString(),
      timestamp: DateTime.now(),
    );

    _recordCrash(crashReport);
  }

  /// Enregistre un crash manuellement
  static Future<void> recordCrash({
    required String type,
    required String error,
    String? stackTrace,
    Map<String, dynamic>? context,
    String? userId,
  }) async {
    final crashReport = CrashReport(
      type: type,
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      context: context?.toString(),
      userId: userId,
    );

    await _recordCrash(crashReport);
  }

  /// Enregistre un crash dans le système
  static Future<void> _recordCrash(CrashReport report) async {
    try {
      // Ajouter aux rapports en attente
      _pendingReports.add(report);

      // Tentative d'envoi immédiat
      await _sendCrashReport(report);

      // Log dans le système d'audit
      await AuditService.logSystemError(
        'crash_detected',
        'Crash détecté: ${report.type} - ${report.error}',
        stackTrace: report.stackTrace,
        context: {
          'crash_type': report.type,
          'error_message': report.error,
          'has_stack_trace': report.stackTrace != null,
          'timestamp': report.timestamp.toIso8601String(),
        },
      );

    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement du crash: $e');
    }
  }

  /// Envoie un rapport de crash vers Supabase
  static Future<void> _sendCrashReport(CrashReport report) async {
    try {
      final user = _supabase.auth.currentUser;
      
      await _supabase.from('crash_reports').insert({
        'id': report.id,
        'user_id': report.userId ?? user?.id,
        'crash_type': report.type,
        'error_message': report.error,
        'stack_trace': report.stackTrace,
        'context_info': report.context,
        'library': report.library,
        'platform': Platform.operatingSystem,
        'app_version': '1.0.0', // À récupérer depuis package_info
        'timestamp': report.timestamp.toIso8601String(),
        'status': 'new',
        'severity': _determineSeverity(report),
        'metadata': {
          'flutter_version': '3.0.0', // À récupérer dynamiquement
          'dart_version': '2.17.0', // À récupérer dynamiquement
          'device_info': await _getDeviceInfo(),
        },
      });

      // Supprimer des rapports en attente si envoyé avec succès
      _pendingReports.removeWhere((r) => r.id == report.id);
      
      debugPrint('Rapport de crash envoyé: ${report.id}');

    } catch (e) {
      debugPrint('Erreur envoi rapport de crash: $e');
    }
  }

  /// Traite les rapports en attente
  static Future<void> _processPendingReports() async {
    if (_pendingReports.isEmpty) return;

    debugPrint('Traitement de ${_pendingReports.length} rapports en attente');

    final reportsToProcess = List<CrashReport>.from(_pendingReports);
    
    for (final report in reportsToProcess) {
      await _sendCrashReport(report);
    }
  }

  /// Détermine la sévérité d'un crash
  static String _determineSeverity(CrashReport report) {
    final error = report.error.toLowerCase();
    
    if (error.contains('fatal') || 
        error.contains('segmentation fault') ||
        error.contains('out of memory')) {
      return 'critical';
    }
    
    if (error.contains('null') ||
        error.contains('assertion') ||
        error.contains('state error')) {
      return 'high';
    }
    
    if (error.contains('network') ||
        error.contains('timeout') ||
        error.contains('connection')) {
      return 'medium';
    }
    
    return 'low';
  }

  /// Récupère les informations de l'appareil
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      return {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
        'locale': Platform.localeName,
        'number_of_processors': Platform.numberOfProcessors,
      };
    } catch (e) {
      return {'error': 'Could not retrieve device info'};
    }
  }

  /// Récupère les statistiques de crash
  static Future<Map<String, dynamic>> getCrashStatistics() async {
    try {
      final now = DateTime.now();
      final last24Hours = now.subtract(const Duration(hours: 24));
      final lastWeek = now.subtract(const Duration(days: 7));
      final lastMonth = now.subtract(const Duration(days: 30));

      // Crashes totaux
      final totalCrashes = await _supabase
          .from('crash_reports')
          .select('id')
          .count();

      // Crashes par période
      final crashesLast24h = await _supabase
          .from('crash_reports')
          .select('id')
          .gte('timestamp', last24Hours.toIso8601String())
          .count();

      final crashesLastWeek = await _supabase
          .from('crash_reports')
          .select('id')
          .gte('timestamp', lastWeek.toIso8601String())
          .count();

      final crashesLastMonth = await _supabase
          .from('crash_reports')
          .select('id')
          .gte('timestamp', lastMonth.toIso8601String())
          .count();

      // Crashes par type
      final crashesByType = await _supabase
          .from('crash_reports')
          .select('crash_type')
          .gte('timestamp', lastMonth.toIso8601String());

      final typeStats = <String, int>{};
      for (final crash in crashesByType) {
        final type = crash['crash_type'] ?? 'unknown';
        typeStats[type] = (typeStats[type] ?? 0) + 1;
      }

      // Crashes par sévérité
      final crashesBySeverity = await _supabase
          .from('crash_reports')
          .select('severity')
          .gte('timestamp', lastMonth.toIso8601String());

      final severityStats = <String, int>{};
      for (final crash in crashesBySeverity) {
        final severity = crash['severity'] ?? 'unknown';
        severityStats[severity] = (severityStats[severity] ?? 0) + 1;
      }

      // Top erreurs
      final topErrors = await _supabase
          .from('crash_reports')
          .select('error_message')
          .gte('timestamp', lastWeek.toIso8601String())
          .limit(10);

      final errorCounts = <String, int>{};
      for (final crash in topErrors) {
        final error = crash['error_message'] ?? 'unknown';
        final shortError = error.length > 100 ? '${error.substring(0, 100)}...' : error;
        errorCounts[shortError] = (errorCounts[shortError] ?? 0) + 1;
      }

      // Taux de crash (approximatif)
      final crashRate = totalCrashes.count > 0 ? 
          (crashesLast24h.count / totalCrashes.count) * 100 : 0.0;

      return {
        'total_crashes': totalCrashes.count,
        'crashes_last_24h': crashesLast24h.count,
        'crashes_last_week': crashesLastWeek.count,
        'crashes_last_month': crashesLastMonth.count,
        'crashes_by_type': typeStats,
        'crashes_by_severity': severityStats,
        'top_errors': errorCounts,
        'crash_rate_24h': crashRate,
        'pending_reports': _pendingReports.length,
        'last_updated': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      debugPrint('Erreur récupération statistiques crash: $e');
      return {};
    }
  }

  /// Récupère les détails d'un crash spécifique
  static Future<Map<String, dynamic>?> getCrashDetails(String crashId) async {
    try {
      final crash = await _supabase
          .from('crash_reports')
          .select('*')
          .eq('id', crashId)
          .single();

      return crash;
    } catch (e) {
      debugPrint('Erreur récupération détails crash: $e');
      return null;
    }
  }

  /// Marque un crash comme résolu
  static Future<void> markCrashAsResolved(String crashId, {String? resolution}) async {
    try {
      await _supabase
          .from('crash_reports')
          .update({
            'status': 'resolved',
            'resolved_at': DateTime.now().toIso8601String(),
            'resolution': resolution,
          })
          .eq('id', crashId);

      await AuditService.logSystemAction(
        'crash_resolved',
        crashId,
        details: {'resolution': resolution},
      );

    } catch (e) {
      debugPrint('Erreur marquage crash résolu: $e');
    }
  }

  /// Supprime les anciens rapports de crash
  static Future<void> cleanupOldCrashes({int daysToKeep = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      final result = await _supabase
          .from('crash_reports')
          .delete()
          .lt('timestamp', cutoffDate.toIso8601String());

      await AuditService.logSystemAction(
        'crash_cleanup',
        'old_crashes_deleted',
        details: {
          'cutoff_date': cutoffDate.toIso8601String(),
          'days_kept': daysToKeep,
        },
      );

      debugPrint('Nettoyage des anciens crashes terminé');

    } catch (e) {
      debugPrint('Erreur nettoyage crashes: $e');
    }
  }
}

/// Modèle pour un rapport de crash
class CrashReport {
  final String id;
  final String type;
  final String error;
  final String? stackTrace;
  final DateTime timestamp;
  final String? context;
  final String? library;
  final String? informationCollector;
  final String? userId;

  CrashReport({
    String? id,
    required this.type,
    required this.error,
    this.stackTrace,
    required this.timestamp,
    this.context,
    this.library,
    this.informationCollector,
    this.userId,
  }) : id = id ?? _generateId();

  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'error': error,
      'stackTrace': stackTrace,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'library': library,
      'informationCollector': informationCollector,
      'userId': userId,
    };
  }
}
