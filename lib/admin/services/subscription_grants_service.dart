import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionGrantsService {
  static final _supabase = Supabase.instance.client;

  /// Attribue un abonnement à un utilisateur
  static Future<String> grantSubscriptionToUser({
    required String userId,
    required String planId,
    required int durationDays,
    String? reason,
    String? adminNotes,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await _supabase.rpc('grant_subscription_to_user', params: {
        'p_user_id': userId,
        'p_plan_id': planId,
        'p_duration_days': durationDays,
        'p_granted_by': currentUser.id,
        'p_reason': reason,
        'p_admin_notes': adminNotes,
      });

      return response as String;
    } catch (e) {
      throw Exception('Erreur lors de l\'attribution de l\'abonnement: $e');
    }
  }

  /// Attribue un abonnement à plusieurs utilisateurs
  static Future<int> grantSubscriptionToMultipleUsers({
    required List<String> userIds,
    required String planId,
    required int durationDays,
    String? reason,
    String? adminNotes,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await _supabase.rpc('grant_subscription_to_multiple_users', params: {
        'p_user_ids': userIds,
        'p_plan_id': planId,
        'p_duration_days': durationDays,
        'p_granted_by': currentUser.id,
        'p_reason': reason,
        'p_admin_notes': adminNotes,
      });

      return response as int;
    } catch (e) {
      throw Exception('Erreur lors de l\'attribution multiple: $e');
    }
  }

  /// Récupère toutes les attributions d'abonnements
  static Future<List<Map<String, dynamic>>> getAllSubscriptionGrants() async {
    try {
      final response = await _supabase
          .from('admin_subscription_grants')
          .select('''
            *,
            user_profiles!user_id(fullname, email, role),
            subscription_plans!plan_id(name, price),
            granted_by_profile:user_profiles!granted_by(fullname)
          ''')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des attributions: $e');
    }
  }

  /// Récupère les attributions d'un utilisateur spécifique
  static Future<List<Map<String, dynamic>>> getUserSubscriptionGrants(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('admin_subscription_grants')
          .select('''
            *,
            subscription_plans!plan_id(name, price, features),
            granted_by_profile:user_profiles!granted_by(fullname)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des attributions utilisateur: $e');
    }
  }

  /// Récupère les statistiques des attributions
  static Future<List<Map<String, dynamic>>> getSubscriptionGrantsStats() async {
    try {
      final response = await _supabase
          .from('admin_subscription_grants_stats')
          .select('''
            *,
            admin_profile:user_profiles!granted_by(fullname, email)
          ''');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des statistiques: $e');
    }
  }

  /// Annule une attribution d'abonnement
  static Future<void> cancelSubscriptionGrant(String grantId) async {
    try {
      // Mettre à jour le statut de l'attribution
      await _supabase
          .from('admin_subscription_grants')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', grantId);

      // Récupérer les détails de l'attribution pour annuler l'abonnement
      final grantResponse = await _supabase
          .from('admin_subscription_grants')
          .select('user_id')
          .eq('id', grantId)
          .single();

      final userId = grantResponse['user_id'];

      // Annuler l'abonnement actuel de l'utilisateur
      await _supabase
          .from('user_subscriptions')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('status', 'active');

    } catch (e) {
      throw Exception('Erreur lors de l\'annulation: $e');
    }
  }

  /// Prolonge une attribution d'abonnement
  static Future<void> extendSubscriptionGrant({
    required String grantId,
    required int additionalDays,
    String? reason,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer l'attribution actuelle
      final grantResponse = await _supabase
          .from('admin_subscription_grants')
          .select('user_id, expires_at, duration_days')
          .eq('id', grantId)
          .single();

      final userId = grantResponse['user_id'];
      final currentExpiresAt = DateTime.parse(grantResponse['expires_at']);
      final currentDuration = grantResponse['duration_days'] as int;
      
      final newExpiresAt = currentExpiresAt.add(Duration(days: additionalDays));
      final newDuration = currentDuration + additionalDays;

      // Mettre à jour l'attribution
      await _supabase
          .from('admin_subscription_grants')
          .update({
            'expires_at': newExpiresAt.toIso8601String(),
            'duration_days': newDuration,
            'admin_notes': reason != null 
                ? 'Prolongé de $additionalDays jours. Raison: $reason'
                : 'Prolongé de $additionalDays jours',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', grantId);

      // Mettre à jour l'abonnement utilisateur
      await _supabase
          .from('user_subscriptions')
          .update({
            'expires_at': newExpiresAt.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('status', 'active');

    } catch (e) {
      throw Exception('Erreur lors de la prolongation: $e');
    }
  }

  /// Recherche des utilisateurs pour attribution
  static Future<List<Map<String, dynamic>>> searchUsersForGrant(
    String query,
  ) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('''
            id, fullname, email, role, phone, created_at,
            user_subscriptions!inner(
              status, expires_at,
              subscription_plans(name, price)
            )
          ''')
          .or('fullname.ilike.%$query%,email.ilike.%$query%,phone.ilike.%$query%')
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Récupère les utilisateurs par rôle
  static Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('''
            id, fullname, email, role, phone, created_at,
            user_subscriptions(
              status, expires_at,
              subscription_plans(name, price)
            )
          ''')
          .eq('role', role)
          .order('fullname', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des utilisateurs: $e');
    }
  }

  /// Récupère les métriques générales des attributions
  static Future<Map<String, dynamic>> getSubscriptionGrantsMetrics() async {
    try {
      // Statistiques générales
      final grantsResponse = await _supabase
          .from('admin_subscription_grants')
          .select('status, duration_days, created_at');

      final grants = List<Map<String, dynamic>>.from(grantsResponse);
      
      // Calculer les métriques
      int totalGrants = grants.length;
      int activeGrants = grants.where((g) => g['status'] == 'active').length;
      int expiredGrants = grants.where((g) => g['status'] == 'expired').length;
      int cancelledGrants = grants.where((g) => g['status'] == 'cancelled').length;
      
      double avgDuration = grants.isNotEmpty 
          ? grants.fold<double>(0.0, (sum, g) => sum + ((g['duration_days'] ?? 0) as num).toDouble()) / grants.length
          : 0.0;

      // Attributions récentes (derniers 7 jours)
      final recentGrants = grants.where((g) {
        final createdAt = DateTime.parse(g['created_at']);
        return createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)));
      }).length;

      // Plans les plus attribués - requête simplifiée
      final plansResponse = await _supabase
          .from('admin_subscription_grants')
          .select('''
            plan_id,
            subscription_plans!plan_id(name)
          ''');

      // Calculer les comptes côté client
      final planCounts = <String, Map<String, dynamic>>{};
      for (final grant in List<Map<String, dynamic>>.from(plansResponse)) {
        final planId = grant['plan_id'] as String;
        final planName = grant['subscription_plans']?['name'] ?? 'Plan inconnu';
        
        if (planCounts.containsKey(planId)) {
          planCounts[planId]!['count'] = (planCounts[planId]!['count'] as int) + 1;
        } else {
          planCounts[planId] = {
            'plan_id': planId,
            'name': planName,
            'count': 1,
          };
        }
      }

      // Trier par nombre d'attributions et prendre les 5 premiers
      final topPlans = planCounts.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      final top5Plans = topPlans.take(5).toList();

      return {
        'total_grants': totalGrants,
        'active_grants': activeGrants,
        'expired_grants': expiredGrants,
        'cancelled_grants': cancelledGrants,
        'avg_duration_days': avgDuration.round(),
        'recent_grants_7_days': recentGrants,
        'top_plans': top5Plans,
      };
    } catch (e) {
      throw Exception('Erreur lors du chargement des métriques: $e');
    }
  }

  /// Recherche des utilisateurs
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      var queryBuilder = _supabase
          .from('user_profiles')
          .select('id, fullname, email, phone, role, created_at');

      if (query.isNotEmpty) {
        queryBuilder = queryBuilder.or(
          'fullname.ilike.%$query%,email.ilike.%$query%,phone.ilike.%$query%'
        );
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors de la recherche d\'utilisateurs: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    try {
      final response = await _supabase
          .from('subscription_plans')
          .select('id, name, description, price, duration_days, features')
          .eq('is_active', true)
          .order('price', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des plans: $e');
    }
  }

  /// Récupère l'historique des abonnements d'un utilisateur
  static Future<List<Map<String, dynamic>>> getUserSubscriptionHistory(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('user_subscriptions')
          .select('''
            *,
            subscription_plans(name, price, features),
            admin_subscription_grants(granted_by, reason, admin_notes)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement de l\'historique: $e');
    }
  }
}
