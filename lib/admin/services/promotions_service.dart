import 'package:supabase_flutter/supabase_flutter.dart';

class PromotionsService {
  static final _supabase = Supabase.instance.client;

  /// Crée une nouvelle promotion
  static Future<String> createPromotion({
    required String name,
    required String description,
    required String promotionType, // 'percentage', 'fixed_amount', 'free_subscription'
    double? discountPercentage,
    double? discountAmount,
    String? freeSubscriptionPlanId,
    required String targetType, // 'all_users', 'specific_users', 'user_role', 'new_users'
    String? targetRole,
    List<String>? targetUserIds,
    double? minSubscriptionPrice,
    DateTime? expiresAt,
    int? maxUses,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await _supabase.rpc('create_admin_promotion', params: {
        'p_name': name,
        'p_description': description,
        'p_promotion_type': promotionType,
        'p_target_type': targetType,
        'p_created_by': currentUser.id,
        'p_discount_percentage': discountPercentage,
        'p_discount_amount': discountAmount,
        'p_free_subscription_plan_id': freeSubscriptionPlanId,
        'p_target_role': targetRole,
        'p_target_user_ids': targetUserIds,
        'p_min_subscription_price': minSubscriptionPrice,
        'p_expires_at': expiresAt?.toIso8601String(),
        'p_max_uses': maxUses,
      });

      return response as String;
    } catch (e) {
      throw Exception('Erreur lors de la création de la promotion: $e');
    }
  }

  /// Récupère toutes les promotions
  static Future<List<Map<String, dynamic>>> getAllPromotions() async {
    try {
      final response = await _supabase
          .from('admin_promotions')
          .select('''
            *,
            subscription_plans!admin_promotions_free_subscription_plan_id_fkey(name),
            admin_promotion_targets(user_id, user_profiles!inner(fullname, email))
          ''')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des promotions: $e');
    }
  }

  /// Récupère les statistiques des promotions
  static Future<List<Map<String, dynamic>>> getPromotionsStats() async {
    try {
      final response = await _supabase
          .from('admin_promotions_stats')
          .select('*')
          .order('total_uses', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des statistiques: $e');
    }
  }

  /// Met à jour une promotion
  static Future<void> updatePromotion(String promotionId,
      Map<String, dynamic> updates,) async {
    try {
      await _supabase
          .from('admin_promotions')
          .update({
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', promotionId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  /// Désactive une promotion
  static Future<void> deactivatePromotion(String promotionId) async {
    try {
      await _supabase
          .from('admin_promotions')
          .update({
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', promotionId);
    } catch (e) {
      throw Exception('Erreur lors de la désactivation: $e');
    }
  }

  /// Supprime une promotion
  static Future<void> deletePromotion(String promotionId) async {
    try {
      await _supabase
          .from('admin_promotions')
          .delete()
          .eq('id', promotionId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  /// Récupère les utilisations d'une promotion
  static Future<List<Map<String, dynamic>>> getPromotionUsage(
      String promotionId,) async {
    try {
      final response = await _supabase
          .from('admin_promotion_usage')
          .select('''
            *,
            user_profiles!user_id(fullname, email, role),
            user_subscriptions(subscription_plans(name, price))
          ''')
          .eq('promotion_id', promotionId)
          .order('used_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des utilisations: $e');
    }
  }

  /// Recherche des utilisateurs pour ciblage
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('id, fullname, email, role, phone')
          .or(
          'fullname.ilike.%$query%,email.ilike.%$query%,phone.ilike.%$query%')
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Récupère les plans d'abonnement disponibles
  static Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    try {
      final response = await _supabase
          .from('subscription_plans')
          .select('*')
          .eq('is_active', true)
          .order('price', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des plans: $e');
    }
  }

  /// Récupère les promotions applicables à un utilisateur
  static Future<List<Map<String, dynamic>>> getUserApplicablePromotions(
      String userId, {
        double? subscriptionPrice,
      }) async {
    try {
      final response = await _supabase.rpc(
        'get_user_applicable_promotions',
        params: {
          'p_user_id': userId,
          'p_subscription_price': subscriptionPrice,
        },
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception(
          'Erreur lors du chargement des promotions applicables: $e');
    }
  }

  /// Applique une promotion à un utilisateur
  static Future<double> applyPromotion({
    required String promotionId,
    required String userId,
    required String subscriptionId,
    required double originalPrice,
  }) async {
    try {
      final response = await _supabase.rpc('apply_admin_promotion', params: {
        'p_promotion_id': promotionId,
        'p_user_id': userId,
        'p_subscription_id': subscriptionId,
        'p_original_price': originalPrice,
      });

      return (response as num).toDouble();
    } catch (e) {
      throw Exception('Erreur lors de l\'application de la promotion: $e');
    }
  }
  /// Récupère les métriques des promotions
  static Future<Map<String, dynamic>> getPromotionsMetrics() async {
    try {
      final response = await _supabase.rpc('get_promotions_metrics');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des métriques: $e');
    }
  }

  /// Récupère une promotion par son ID
  static Future<Map<String, dynamic>?> getPromotionById(String promotionId) async {
    try {
      final response = await _supabase
          .from('admin_promotions')
          .select('*')
          .eq('id', promotionId)
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement de la promotion: $e');
    }
  }

  /// Récupère l'historique d'utilisation d'une promotion
  static Future<List<Map<String, dynamic>>> getPromotionUsageHistory(String promotionId) async {
    try {
      final response = await _supabase
          .from('admin_promotion_usage')
          .select('''
            *,
            user_profiles!user_id(id, fullname, email, role)
          ''')
          .eq('promotion_id', promotionId)
          .order('used_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement de l\'historique: $e');
    }
  }

  /// Récupère les utilisateurs ciblés par une promotion
  static Future<List<Map<String, dynamic>>> getPromotionTargetUsers(String promotionId) async {
    try {
      final response = await _supabase
          .from('admin_promotion_targets')
          .select('''
            user_id,
            user_profiles!user_id(id, fullname, email, phone, role)
          ''')
          .eq('promotion_id', promotionId);

      return List<Map<String, dynamic>>.from(response)
          .map((item) => item['user_profiles'])
          .where((user) => user != null)
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des utilisateurs ciblés: $e');
    }
  }

  /// Met à jour le statut d'une promotion
  static Future<void> updatePromotionStatus(String promotionId, bool isActive) async {
    try {
      await _supabase
          .from('admin_promotions')
          .update({'is_active': isActive, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', promotionId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }
}