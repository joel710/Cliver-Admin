import 'package:supabase_flutter/supabase_flutter.dart';
import 'maintenance_service.dart';

class AppConfigService {
  static final _supabase = Supabase.instance.client;

  // Notifications Push
  static Future<Map<String, dynamic>> sendPushNotificationToAll({
    required String title,
    required String message,
    String? actionUrl,
  }) async {
    try {
      print('🚀 Début envoi notification à tous les utilisateurs');
      print('📝 Titre: $title');
      print('💬 Message: $message');
      print('🔗 URL: $actionUrl');
      
      final response = await _supabase.rpc('send_push_notification_all', params: {
        'notification_title': title,
        'notification_message': message,
        'action_url': actionUrl,
      });
      
      print('📦 Réponse brute: $response');
      print('📊 Type de réponse: ${response.runtimeType}');
      
      if (response != null && response is List && response.isNotEmpty) {
        final result = response.first;
        print('✅ Résultat parsé: $result');
        
        return {
          'success': result['success'] ?? false,
          'sent_count': result['sent_count'] ?? 0,
          'failed_count': result['failed_count'] ?? 0,
          'details': result['details'] ?? {},
        };
      }
      
      print('❌ Réponse invalide ou vide');
      return {
        'success': false,
        'sent_count': 0,
        'failed_count': 0,
        'details': {'error': 'Réponse invalide du serveur: $response'},
      };
    } catch (e, stackTrace) {
      print('💥 Erreur envoi notification: $e');
      print('📍 Stack trace: $stackTrace');
      
      return {
        'success': false,
        'sent_count': 0,
        'failed_count': 0,
        'details': {
          'error': e.toString(),
          'type': e.runtimeType.toString(),
          'stack_trace': stackTrace.toString().split('\n').take(3).join('\n'),
        },
      };
    }
  }

  // Mode Maintenance - VERSION CORRIGÉE
  static Future<bool> setMaintenanceMode({
    required bool enabled,
    String? message,
    DateTime? scheduledEnd,
  }) async {
    try {
      print('🔧 Tentative de mise à jour du mode maintenance...');
      print('📊 Enabled: $enabled');
      
      // SOLUTION 1: Essayer d'abord une mise à jour
      final updateResponse = await _supabase
        .from('app_config')
        .update({
          'value': {
            'enabled': enabled,
            'message': message ?? 'Application en maintenance. Veuillez réessayer plus tard.',
            'scheduled_end': scheduledEnd?.toIso8601String(),
          },
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('key', 'maintenance_mode')
        .select();
      
      print('📦 Update response: $updateResponse');
      
      // Si la mise à jour n'a affecté aucune ligne, insérer
      if (updateResponse.isEmpty) {
        print('🆕 Aucune ligne mise à jour, insertion...');
        
        await _supabase.from('app_config').insert({
          'key': 'maintenance_mode',
          'value': {
            'enabled': enabled,
            'message': message ?? 'Application en maintenance. Veuillez réessayer plus tard.',
            'scheduled_end': scheduledEnd?.toIso8601String(),
          },
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      
      print('✅ Mode maintenance configuré avec succès');
      
      // Invalider le cache pour forcer la vérification
      await MaintenanceService.invalidateCache();
      
      return true;
    } catch (e) {
      print('💥 Erreur mode maintenance: $e');
      
      // SOLUTION 2: Si erreur de conflit, forcer la mise à jour
      if (e is PostgrestException && e.code == '23505') {
        try {
          print('🔄 Conflit détecté, mise à jour forcée...');
          
          await _supabase
            .from('app_config')
            .update({
              'value': {
                'enabled': enabled,
                'message': message ?? 'Application en maintenance. Veuillez réessayer plus tard.',
                'scheduled_end': scheduledEnd?.toIso8601String(),
              },
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('key', 'maintenance_mode');
            
          print('✅ Mise à jour forcée réussie');
          await MaintenanceService.invalidateCache();
          return true;
        } catch (updateError) {
          print('💥 Erreur lors de la mise à jour forcée: $updateError');
          return false;
        }
      }
      
      return false;
    }
  }

  // ALTERNATIVE: Version avec upsert explicite
  static Future<bool> setMaintenanceModeUpsert({
    required bool enabled,
    String? message,
    DateTime? scheduledEnd,
  }) async {
    try {
      print('🔧 Upsert mode maintenance...');
      
      // Spécifier explicitement le conflit et l'option ignoreDuplicates
      final response = await _supabase
        .from('app_config')
        .upsert({
          'key': 'maintenance_mode',
          'value': {
            'enabled': enabled,
            'message': message ?? 'Application en maintenance. Veuillez réessayer plus tard.',
            'scheduled_end': scheduledEnd?.toIso8601String(),
          },
          'updated_at': DateTime.now().toIso8601String(),
        }, 
        onConflict: 'key',
        ignoreDuplicates: false  // Force la mise à jour en cas de conflit
      );
      
      print('✅ Upsert réussi: $response');
      await MaintenanceService.invalidateCache();
      return true;
    } catch (e) {
      print('💥 Erreur upsert: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getMaintenanceStatus() async {
    try {
      final response = await _supabase
          .from('app_config')
          .select('value')
          .eq('key', 'maintenance_mode')
          .maybeSingle();
      return response?['value'];
    } catch (e) {
      print('Erreur récupération maintenance: $e');
      return null;
    }
  }

  // Gestion des versions - VERSION CORRIGÉE
  static Future<bool> setAppVersion({
    required String platform, // 'android' ou 'ios'
    required String minVersion,
    required String currentVersion,
    required bool forceUpdate,
    String? updateMessage,
  }) async {
    try {
      // Utiliser la même approche corrigée
      final updateResponse = await _supabase
        .from('app_config')
        .update({
          'value': {
            'min_version': minVersion,
            'current_version': currentVersion,
            'force_update': forceUpdate,
            'update_message': updateMessage ?? 'Une nouvelle version est disponible.',
          },
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('key', 'app_version_$platform')
        .select();
      
      if (updateResponse.isEmpty) {
        await _supabase.from('app_config').insert({
          'key': 'app_version_$platform',
          'value': {
            'min_version': minVersion,
            'current_version': currentVersion,
            'force_update': forceUpdate,
            'update_message': updateMessage ?? 'Une nouvelle version est disponible.',
          },
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      
      return true;
    } catch (e) {
      print('Erreur version app: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getAppVersion(String platform) async {
    try {
      final response = await _supabase
          .from('app_config')
          .select('value')
          .eq('key', 'app_version_$platform')
          .maybeSingle();
      return response?['value'];
    } catch (e) {
      print('Erreur récupération version: $e');
      return null;
    }
  }

  // Paramètres globaux - VERSION CORRIGÉE
  static Future<bool> setGlobalSettings({
    int? waitTimeSeconds,
    double? searchRadiusKm,
    int? maxDriversPerRequest,
    double? baseFare,
    double? farePerKm,
  }) async {
    try {
      final settings = <String, dynamic>{};
      if (waitTimeSeconds != null) settings['wait_time_seconds'] = waitTimeSeconds;
      if (searchRadiusKm != null) settings['search_radius_km'] = searchRadiusKm;
      if (maxDriversPerRequest != null) settings['max_drivers_per_request'] = maxDriversPerRequest;
      if (baseFare != null) settings['base_fare'] = baseFare;
      if (farePerKm != null) settings['fare_per_km'] = farePerKm;

      // Même approche corrigée
      final updateResponse = await _supabase
        .from('app_config')
        .update({
          'value': settings,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('key', 'global_settings')
        .select();
      
      if (updateResponse.isEmpty) {
        await _supabase.from('app_config').insert({
          'key': 'global_settings',
          'value': settings,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      
      return true;
    } catch (e) {
      print('Erreur paramètres globaux: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getGlobalSettings() async {
    try {
      final response = await _supabase
          .from('app_config')
          .select('value')
          .eq('key', 'global_settings')
          .maybeSingle();
      return response?['value'];
    } catch (e) {
      print('Erreur récupération paramètres: $e');
      return null;
    }
  }

  // Historique des configurations
  static Future<List<Map<String, dynamic>>> getConfigHistory() async {
    try {
      final response = await _supabase
          .from('app_config')
          .select('key, value, updated_at')
          .order('updated_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur historique config: $e');
      return [];
    }
  }

  // Méthode pour nettoyer les doublons (à utiliser une fois)
  static Future<void> cleanupDuplicates() async {
    try {
      print('🧹 Nettoyage des doublons...');
      
      // Supprimer les doublons de maintenance_mode
      await _supabase.rpc('cleanup_duplicates', params: {
        'table_name': 'app_config',
        'key_column': 'key',
        'keep_latest': true
      });
      
      print('✅ Nettoyage terminé');
    } catch (e) {
      print('💥 Erreur nettoyage: $e');
    }
  }
}
