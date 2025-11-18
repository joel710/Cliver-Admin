import 'package:supabase_flutter/supabase_flutter.dart';

class DriversService {
  static final client = Supabase.instance.client;

  /// Récupère la liste de tous les livreurs
  static Future<List<Map<String, dynamic>>> getAllDrivers() async {
    try {
      final res = await client
          .from('user_profiles')
          .select('''
            id,
            fullname,
            phone,
            is_available,
            role,
            latitude,
            longitude,
            created_at,
            kyc_verified,
            kyc_verified_at,
            pseudo,
            verified
          ''')
          .eq('role', 'livreur')
          .order('created_at', ascending: false);

      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Erreur lors du chargement des livreurs: $e');
    }
  }

  /// Récupère les livreurs par statut de disponibilité
  static Future<List<Map<String, dynamic>>> getDriversByStatus(
    String status,
  ) async {
    try {
      final res = await client
          .from('user_profiles')
          .select('''
            id,
            fullname,
            phone,
            is_available,
            role,
            latitude,
            longitude,
            created_at,
            kyc_verified,
            kyc_verified_at,
            pseudo,
            verified
          ''')
          .eq('role', 'livreur')
          .eq('is_available', status == 'available')
          .order('created_at', ascending: false);

      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Erreur lors du chargement des livreurs: $e');
    }
  }

  /// Récupère le profil détaillé d'un livreur
  static Future<Map<String, dynamic>> getDriverProfile(String driverId) async {
    try {
      final res = await client
          .from('user_profiles')
          .select('''
            id,
            fullname,
            phone,
            is_available,
            role,
            latitude,
            longitude,
            created_at,
            kyc_verified,
            kyc_verified_at,
            pseudo,
            avatar_url,
            verified
          ''')
          .eq('id', driverId)
          .eq('role', 'livreur')
          .single();

      return res;
    } catch (e) {
      throw Exception('Erreur lors du chargement du profil: $e');
    }
  }

  /// Met à jour le statut de disponibilité d'un livreur
  static Future<void> updateDriverAvailability(
    String driverId,
    bool isAvailable,
  ) async {
    try {
      await client
          .from('user_profiles')
          .update({'is_available': isAvailable})
          .eq('id', driverId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la disponibilité: $e');
    }
  }

  /// Suspend un livreur (désactive son compte)
  static Future<void> suspendDriver(String driverId, String reason) async {
    try {
      await client
          .from('user_profiles')
          .update({'is_available': false, 'verified': false})
          .eq('id', driverId);

      // TODO: Ajouter une table pour l'historique des suspensions
    } catch (e) {
      throw Exception('Erreur lors de la suspension: $e');
    }
  }

  /// Réactive un livreur (retire la suspension)
  static Future<void> unsuspendDriver(String driverId) async {
    try {
      await client
          .from('user_profiles')
          .update({'verified': true, 'is_available': true})
          .eq('id', driverId);
    } catch (e) {
      throw Exception('Erreur lors de la réactivation: $e');
    }
  }

  /// Récupère les statistiques des livreurs
  static Future<Map<String, dynamic>> getDriversStats() async {
    try {
      final totalDrivers = await client
          .from('user_profiles')
          .select('id')
          .eq('role', 'livreur');

      final availableDrivers = await client
          .from('user_profiles')
          .select('id')
          .eq('role', 'livreur')
          .eq('is_available', true);

      final kycVerifiedDrivers = await client
          .from('user_profiles')
          .select('id')
          .eq('role', 'livreur')
          .eq('kyc_verified', true);

      final activeMissions = await client
          .from('missions')
          .select('id')
          .or('status.eq.en_livraison,status.eq.attribuée');

      return {
        'total': totalDrivers.length,
        'available': availableDrivers.length,
        'kyc_verified': kycVerifiedDrivers.length,
        'active_missions': activeMissions.length,
      };
    } catch (e) {
      throw Exception('Erreur lors du chargement des statistiques: $e');
    }
  }

  /// Récupère l'historique des missions d'un livreur
  static Future<List<Map<String, dynamic>>> getDriverMissionHistory(
    String driverId,
  ) async {
    try {
      final res = await client
          .from('missions')
          .select('''
            id,
            title,
            description,
            start_address,
            end_address,
            status,
            prix,
            created_at,
            delivery_outcome,
            delivery_comment
          ''')
          .eq('livreur_id', driverId)
          .order('created_at', ascending: false)
          .limit(50);

      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Erreur lors du chargement de l\'historique: $e');
    }
  }

  /// Récupère la localisation en temps réel d'un livreur
  static Future<Map<String, dynamic>?> getDriverLocation(
    String driverId,
  ) async {
    try {
      // D'abord, vérifier la dernière position dans user_profiles
      final profileRes = await client
          .from('user_profiles')
          .select('latitude, longitude, updated_at')
          .eq('id', driverId)
          .single();

      if (profileRes['latitude'] != null && profileRes['longitude'] != null) {
        return {
          'latitude': profileRes['latitude'],
          'longitude': profileRes['longitude'],
          'timestamp': profileRes['updated_at'],
          'source': 'profile',
        };
      }

      // Sinon, vérifier dans livreur_tracking
      final trackingRes = await client
          .from('livreur_tracking')
          .select('lat, lng, timestamp')
          .eq('livreur_id', driverId)
          .order('timestamp', ascending: false)
          .limit(1)
          .single();

      if (trackingRes['lat'] != null && trackingRes['lng'] != null) {
        return {
          'latitude': trackingRes['lat'],
          'longitude': trackingRes['lng'],
          'timestamp': trackingRes['timestamp'],
          'source': 'tracking',
        };
      }

      return null;
    } catch (e) {
      // Pas de localisation disponible
      return null;
    }
  }

  /// Récupère les évaluations d'un livreur
  static Future<List<Map<String, dynamic>>> getDriverRatings(
    String driverId,
  ) async {
    try {
      final res = await client
          .from('ratings')
          .select('''
            id,
            rating,
            comment,
            created_at,
            mission_id
          ''')
          .eq('rated_id', driverId)
          .order('created_at', ascending: false)
          .limit(20);

      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Erreur lors du chargement des évaluations: $e');
    }
  }

  /// Récupère les statistiques de performance d'un livreur
  static Future<Map<String, dynamic>> getDriverPerformanceStats(
    String driverId,
  ) async {
    try {
      final missions = await client
          .from('missions')
          .select('status, prix, delivery_outcome')
          .eq('livreur_id', driverId);

      final ratings = await client
          .from('ratings')
          .select('rating')
          .eq('rated_id', driverId);

      int totalMissions = missions.length;
      int completedMissions = missions
          .where((m) => m['status'] == 'livrée')
          .length;
      int successfulDeliveries = missions
          .where((m) => m['delivery_outcome'] == 'livré')
          .length;

      double totalRevenue = missions
          .where((m) => m['status'] == 'livrée')
          .fold(0.0, (sum, m) => sum + (m['prix'] ?? 0.0));

      double averageRating = 0.0;
      if (ratings.isNotEmpty) {
        averageRating =
            ratings.map((r) => r['rating'] ?? 0).reduce((a, b) => a + b) /
            ratings.length;
      }

      return {
        'total_missions': totalMissions,
        'completed_missions': completedMissions,
        'successful_deliveries': successfulDeliveries,
        'success_rate': totalMissions > 0
            ? (successfulDeliveries / totalMissions * 100)
            : 0.0,
        'total_revenue': totalRevenue,
        'average_rating': averageRating,
        'total_ratings': ratings.length,
      };
    } catch (e) {
      throw Exception(
        'Erreur lors du chargement des statistiques de performance: $e',
      );
    }
  }
}
