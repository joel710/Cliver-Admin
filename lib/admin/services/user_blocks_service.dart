import 'package:supabase_flutter/supabase_flutter.dart';

class UserBlocksService {
  static final _client = Supabase.instance.client;

  /// Récupère tous les blocages via la vue admin
  static Future<List<Map<String, dynamic>>> getAllBlocks() async {
    try {
      final res = await _client
          .from('admin_user_blocks_view')
          .select('*')
          .order('created_at', ascending: false);

      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Erreur lors du chargement des blocages: $e');
    }
  }

  /// Récupère les blocages pour un utilisateur spécifique
  static Future<List<Map<String, dynamic>>> getBlocksForUser(String userId) async {
    try {
      final res = await _client
          .from('admin_user_blocks_view')
          .select('*')
          .or('blocker_id.eq.$userId,blocked_id.eq.$userId')
          .order('created_at', ascending: false);

      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Erreur lors du chargement des blocages de l\'utilisateur: $e');
    }
  }

  /// Supprime un blocage (déblocage administratif)
  static Future<void> removeBlock(String blockerId, String blockedId) async {
    try {
      await _client
          .from('user_blocks')
          .delete()
          .eq('blocker_id', blockerId)
          .eq('blocked_id', blockedId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du blocage: $e');
    }
  }

  /// Vérifie si deux utilisateurs sont bloqués
  static Future<bool> areUsersBlocked(String user1Id, String user2Id) async {
    try {
      final res = await _client
          .rpc('are_users_blocked', params: {
            'user1_id': user1Id,
            'user2_id': user2Id,
          });

      return res as bool;
    } catch (e) {
      throw Exception('Erreur lors de la vérification du blocage: $e');
    }
  }

  /// Récupère les statistiques des blocages
  static Future<Map<String, dynamic>> getBlocksStats() async {
    try {
      // Compter les blocages actifs
      final activeBlocksResponse = await _client
          .from('user_blocks')
          .select('id');
      final activeBlocksCount = activeBlocksResponse.length;

      // Compter les anciens signalements de type block
      final oldReportsResponse = await _client
          .from('user_reports')
          .select('id')
          .eq('reason', 'block');
      final oldReportsCount = oldReportsResponse.length;

      // Compter les utilisateurs uniques bloqués
      final blockedUsers = await _client
          .from('user_blocks')
          .select('blocked_id');

      final uniqueBlockedUsers = <String>{};
      for (final block in blockedUsers) {
        uniqueBlockedUsers.add(block['blocked_id'] as String);
      }

      return {
        'total_blocks': activeBlocksCount,
        'old_reports': oldReportsCount,
        'unique_blocked_users': uniqueBlockedUsers.length,
      };
    } catch (e) {
      throw Exception('Erreur lors du chargement des statistiques: $e');
    }
  }

  /// Récupère les utilisateurs les plus bloqués
  static Future<List<Map<String, dynamic>>> getMostBlockedUsers() async {
    try {
      final res = await _client
          .from('user_blocks')
          .select('''
            blocked_id,
            user_profiles!user_blocks_blocked_id_fkey(fullname, role)
          ''');

      // Grouper par utilisateur bloqué
      final Map<String, Map<String, dynamic>> blockedCounts = {};
      
      for (final block in res) {
        final blockedId = block['blocked_id'] as String;
        final profile = block['user_profiles'] as Map<String, dynamic>?;
        
        if (blockedCounts.containsKey(blockedId)) {
          blockedCounts[blockedId]!['count'] = 
              (blockedCounts[blockedId]!['count'] as int) + 1;
        } else {
          blockedCounts[blockedId] = {
            'user_id': blockedId,
            'fullname': profile?['fullname'] ?? 'Utilisateur inconnu',
            'role': profile?['role'] ?? 'unknown',
            'count': 1,
          };
        }
      }

      final result = blockedCounts.values.toList();
      result.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      return result.take(10).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des utilisateurs les plus bloqués: $e');
    }
  }
}
