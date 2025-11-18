import 'package:supabase_flutter/supabase_flutter.dart';

class ClientsService {
  static final _client = Supabase.instance.client;

  // Returns a list of clients with profile info and merged last position (if any)
  static Future<List<Map<String, dynamic>>> getClientsWithPresence() async {
    // Fetch clients profiles
    final profiles = await _client
        .from('user_profiles')
        .select(
          'id, fullname, phone, role, created_at, latitude, longitude',
        )
        .eq('role', 'client');

    final List<Map<String, dynamic>> clients = List<Map<String, dynamic>>.from(
      profiles,
    );

    if (clients.isEmpty) return clients;

    // Fetch positions for these clients
    final ids = clients.map((e) => e['id'] as String).toList();
    final positions = await _client
        .from('livreur_tracking')
        .select('livreur_id, lat, lng, timestamp')
        .inFilter('livreur_id', ids)
        .order('timestamp', ascending: false);

    final Map<String, Map<String, dynamic>> posByUser = {
      for (final p in List<Map<String, dynamic>>.from(positions))
        p['livreur_id'] as String: p,
    };

    for (final c in clients) {
      final p = posByUser[c['id'] as String];
      if (p != null) {
        c['lat'] = p['lat'];
        c['lng'] = p['lng'];
        c['last_seen'] = p['timestamp'];
        // Simuler le statut en ligne basé sur la dernière activité
        final lastSeen = DateTime.tryParse(p['timestamp'] ?? '');
        if (lastSeen != null) {
          final now = DateTime.now();
          final difference = now.difference(lastSeen);
          c['is_online'] =
              difference.inMinutes < 30; // En ligne si activité < 30 min
        } else {
          c['is_online'] = false;
        }
      } else {
        c['is_online'] = false;
        c['lat'] = null;
        c['lng'] = null;
        c['last_seen'] = null;
      }
    }

    return clients;
  }

  /// Cette méthode est obsolète - utiliser UserBlocksService à la place
  @deprecated
  static Future<void> toggleClientBlock(String clientId, bool block) async {
    throw Exception('Méthode obsolète - utiliser UserBlocksService pour gérer les blocages');
  }

  /// Récupère les statistiques des clients
  static Future<Map<String, dynamic>> getClientsStats() async {
    try {
      final totalClients = await _client
          .from('user_profiles')
          .select('id')
          .eq('role', 'client');

      // Note: Les statistiques de blocage sont maintenant gérées par UserBlocksService
      // Ici on compte tous les clients comme actifs car is_blocked n'existe plus
      final blockedClients = <dynamic>[];
      final activeClients = totalClients;

      return {
        'total': totalClients.length,
        'blocked': blockedClients.length,
        'active': activeClients.length,
      };
    } catch (e) {
      throw Exception('Erreur lors du chargement des statistiques: $e');
    }
  }

  /// Récupère l'historique des missions d'un client
  static Future<List<Map<String, dynamic>>> getClientMissionHistory(
    String clientId,
  ) async {
    try {
      final res = await _client
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
            delivery_outcome
          ''')
          .eq('client_id', clientId)
          .order('created_at', ascending: false)
          .limit(50);

      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Erreur lors du chargement de l\'historique: $e');
    }
  }

  /// Récupère le profil détaillé d'un client
  static Future<Map<String, dynamic>> getClientProfile(String clientId) async {
    try {
      final res = await _client
          .from('user_profiles')
          .select('''
            id,
            fullname,
            phone,
            role,
            created_at,
            latitude,
            longitude
          ''')
          .eq('id', clientId)
          .eq('role', 'client')
          .single();

      return res;
    } catch (e) {
      throw Exception('Erreur lors du chargement du profil: $e');
    }
  }
}
