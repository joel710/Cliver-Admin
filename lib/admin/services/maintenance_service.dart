import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MaintenanceService {
  static final _supabase = Supabase.instance.client;
  static const String _cacheKey = 'maintenance_status';
  static const String _lastCheckKey = 'maintenance_last_check';
  static const int _cacheValidityMinutes = 5;

  /// Vérifie si l'application est en mode maintenance
  static Future<MaintenanceStatus> checkMaintenanceStatus() async {
    try {
      // Vérifier le cache local d'abord
      final cachedStatus = await _getCachedStatus();
      if (cachedStatus != null) {
        return cachedStatus;
      }

      // Récupérer depuis la base de données
      final response = await _supabase
          .from('app_config')
          .select('value')
          .eq('key', 'maintenance_mode')
          .maybeSingle();

      if (response != null) {
        final config = response['value'] as Map<String, dynamic>;
        final status = MaintenanceStatus.fromJson(config);
        
        // Mettre en cache
        await _cacheStatus(status);
        
        return status;
      }

      // Pas de configuration trouvée, mode normal
      return MaintenanceStatus(enabled: false);
    } catch (e) {
      print('Erreur vérification maintenance: $e');
      // En cas d'erreur, permettre l'accès (fail-safe)
      return MaintenanceStatus(enabled: false);
    }
  }

  /// Vérifie si l'utilisateur actuel est admin et peut bypasser la maintenance
  static Future<bool> canBypassMaintenance() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('user_profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      return response?['role'] == 'admin';
    } catch (e) {
      print('Erreur vérification admin: $e');
      return false;
    }
  }

  /// Invalide le cache de maintenance (à appeler après modification)
  static Future<void> invalidateCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_lastCheckKey);
  }

  /// Récupère le statut depuis le cache local
  static Future<MaintenanceStatus?> _getCachedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Vérifier si le cache est encore valide
      if (now - lastCheck < _cacheValidityMinutes * 60 * 1000) {
        final cachedJson = prefs.getString(_cacheKey);
        if (cachedJson != null) {
          final Map<String, dynamic> json = 
              Map<String, dynamic>.from(Uri.splitQueryString(cachedJson));
          return MaintenanceStatus.fromJson(json);
        }
      }
    } catch (e) {
      print('Erreur lecture cache maintenance: $e');
    }
    return null;
  }

  /// Met en cache le statut de maintenance
  static Future<void> _cacheStatus(MaintenanceStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = status.toJson();
      final jsonString = Uri(queryParameters: json.map((k, v) => MapEntry(k, v.toString()))).query;
      
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Erreur cache maintenance: $e');
    }
  }
}

class MaintenanceStatus {
  final bool enabled;
  final String message;
  final DateTime? scheduledEnd;

  MaintenanceStatus({
    required this.enabled,
    this.message = 'Application en maintenance. Veuillez réessayer plus tard.',
    this.scheduledEnd,
  });

  factory MaintenanceStatus.fromJson(Map<String, dynamic> json) {
    return MaintenanceStatus(
      enabled: json['enabled'] ?? false,
      message: json['message'] ?? 'Application en maintenance. Veuillez réessayer plus tard.',
      scheduledEnd: json['scheduled_end'] != null 
          ? DateTime.tryParse(json['scheduled_end']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'message': message,
      'scheduled_end': scheduledEnd?.toIso8601String(),
    };
  }

  /// Vérifie si la maintenance est encore active (pas expirée)
  bool get isActive {
    if (!enabled) return false;
    if (scheduledEnd == null) return true;
    return DateTime.now().isBefore(scheduledEnd!);
  }

  /// Temps restant avant la fin de maintenance
  Duration? get timeRemaining {
    if (scheduledEnd == null || !isActive) return null;
    return scheduledEnd!.difference(DateTime.now());
  }
}
