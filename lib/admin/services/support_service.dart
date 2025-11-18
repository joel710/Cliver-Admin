import 'package:supabase_flutter/supabase_flutter.dart';

class SupportService {
  static final client = Supabase.instance.client;

  /// Récupère tous les tickets de support
  static Future<List<Map<String, dynamic>>> getAllTickets() async {
    try {
      final res = await client
          .from('tickets_support')
          .select('''
            id,
            user_id,
            user_nom,
            user_role,
            probleme,
            priorite,
            statut,
            date_creation,
            date_resolution,
            admin_assigne
          ''')
          .order('date_creation', ascending: false);

      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Erreur lors du chargement des tickets: $e');
    }
  }

  /// Récupère les tickets par statut
  static Future<List<Map<String, dynamic>>> getTicketsByStatus(
    String status,
  ) async {
    try {
      final res = await client
          .from('tickets_support')
          .select('''
            id,
            user_id,
            user_nom,
            user_role,
            probleme,
            priorite,
            statut,
            date_creation,
            date_resolution
          ''')
          .eq('statut', status)
          .order('date_creation', ascending: false);

      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Erreur lors du chargement des tickets: $e');
    }
  }

  /// Récupère les tickets par priorité
  static Future<List<Map<String, dynamic>>> getTicketsByPriority(
    String priority,
  ) async {
    try {
      final res = await client
          .from('tickets_support')
          .select('''
            id,
            user_id,
            user_nom,
            user_role,
            probleme,
            statut,
            date_creation
          ''')
          .eq('priorite', priority)
          .order('date_creation', ascending: false);

      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Erreur lors du chargement des tickets: $e');
    }
  }

  /// Crée un nouveau ticket de support
  static Future<String> createTicket(Map<String, dynamic> ticketData) async {
    try {
      final res = await client
          .from('tickets_support')
          .insert({
            'user_id': ticketData['user_id'],
            'user_nom': ticketData['user_nom'],
            'user_role': ticketData['user_role'] ?? 'client',
            'probleme': ticketData['probleme'],
            'priorite': ticketData['priorite'] ?? 'medium',
            'statut': 'open',
            'date_creation': DateTime.now().toIso8601String(),
            'admin_assigne': ticketData['admin_id'],
          })
          .select('id')
          .single();

      return res['id'] as String;
    } catch (e) {
      throw Exception('Erreur lors de la création du ticket: $e');
    }
  }


  /// Récupère les statistiques des tickets
  static Future<Map<String, dynamic>> getTicketsStats() async {
    try {
      final openTickets = await client
          .from('tickets_support')
          .select('id')
          .eq('statut', 'open');

      final inProgressTickets = await client
          .from('tickets_support')
          .select('id')
          .eq('statut', 'in_progress');

      final resolvedTickets = await client
          .from('tickets_support')
          .select('id')
          .eq('statut', 'resolved');

      final urgentTickets = await client
          .from('tickets_support')
          .select('id')
          .eq('priorite', 'urgent');

      return {
        'open': openTickets.length,
        'in_progress': inProgressTickets.length,
        'resolved': resolvedTickets.length,
        'urgent': urgentTickets.length,
      };
    } catch (e) {
      throw Exception('Erreur lors du chargement des statistiques: $e');
    }
  }

  /// Récupère l'historique des tickets d'un utilisateur
  static Future<List<Map<String, dynamic>>> getUserTickets(
    String userId,
  ) async {
    try {
      final res = await client
          .from('tickets_support')
          .select('''
            id,
            user_nom,
            user_role,
            probleme,
            priorite,
            statut,
            date_creation,
            date_resolution
          ''')
          .eq('user_id', userId)
          .order('date_creation', ascending: false);

      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Erreur lors du chargement de l\'historique: $e');
    }
  }


  /// Met à jour le statut d'un ticket (mise à jour)
  static Future<void> updateTicketStatus(
    String ticketId,
    String newStatus,
  ) async {
    try {
      final updateData = {'statut': newStatus};

      if (newStatus == 'resolved' || newStatus == 'closed') {
        updateData['date_resolution'] = DateTime.now().toIso8601String();
      }

      await client
          .from('tickets_support')
          .update(updateData)
          .eq('id', ticketId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du ticket: $e');
    }
  }


  /// Assigne un admin à un ticket (mise à jour)
  static Future<void> assignTicket(String ticketId, String adminId) async {
    try {
      await client
          .from('tickets_support')
          .update({
            'admin_assigne': adminId,
            'statut': 'in_progress', // Passer automatiquement en cours
          })
          .eq('id', ticketId);
    } catch (e) {
      throw Exception('Erreur lors de l\'assignation du ticket: $e');
    }
  }

  // ========== NOUVELLES MÉTHODES SIMPLES POUR REAL-TIME ==========

  /// Ajoute un commentaire d'admin à un ticket
  static Future<void> addTicketComment(
    String ticketId,
    String message,
  ) async {
    try {
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      await client.from('commentaires_tickets').insert({
        'ticket_id': ticketId,
        'message': message,
        'sender_type': 'admin',
        'sender_id': currentUser.id,
        'sender_name': 'Support Admin',
        'date_creation': DateTime.now().toIso8601String(),
        'read': false,
      });

      print('✅ [ADMIN] Commentaire admin ajouté avec succès au ticket: $ticketId');

    } catch (e) {
      print('❌ [ADMIN] Erreur ajout commentaire: $e');
      throw Exception('Erreur lors de l\'ajout du commentaire: $e');
    }
  }

  /// Ajoute une réponse d'utilisateur à un ticket
  static Future<void> addUserResponse(
    String ticketId,
    String userId,
    String userName,
    String message,
  ) async {
    try {
      await client.from('commentaires_tickets').insert({
        'ticket_id': ticketId,
        'message': message,
        'sender_type': 'user',
        'sender_id': userId,
        'sender_name': userName,
        'date_creation': DateTime.now().toIso8601String(),
        'read': false,
      });

      print('✅ [ADMIN] Réponse utilisateur ajoutée avec succès au ticket: $ticketId');

    } catch (e) {
      print('❌ [ADMIN] Erreur ajout réponse utilisateur: $e');
      throw Exception('Erreur lors de l\'ajout de la réponse utilisateur: $e');
    }
  }

  /// Récupère tous les commentaires d'un ticket
  static Future<List<Map<String, dynamic>>> getTicketComments(String ticketId) async {
    try {
      final response = await client
          .from('commentaires_tickets')
          .select('*')
          .eq('ticket_id', ticketId)
          .order('date_creation', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des commentaires: $e');
    }
  }

  /// Marque les messages comme lus pour un utilisateur
  static Future<void> markMessagesAsRead(String ticketId, String userId) async {
    try {
      await client
          .from('commentaires_tickets')
          .update({'read': true})
          .eq('ticket_id', ticketId)
          .neq('sender_id', userId)
          .eq('read', false);

      print('✅ [ADMIN] Messages marqués comme lus pour ticket: $ticketId');

    } catch (e) {
      print('❌ [ADMIN] Erreur marquage messages lus: $e');
      throw Exception('Erreur lors du marquage des messages: $e');
    }
  }

  /// Compte les messages non lus d'un ticket pour un utilisateur
  static Future<int> getUnreadMessagesCount(String ticketId, String userId) async {
    try {
      final response = await client
          .from('commentaires_tickets')
          .select('id')
          .eq('ticket_id', ticketId)
          .neq('sender_id', userId)
          .eq('read', false);

      return response.length;
    } catch (e) {
      print('❌ [ADMIN] Erreur comptage messages non lus: $e');
      return 0;
    }
  }

  /// Ferme définitivement un ticket (archivage + empêche nouveaux commentaires)
  static Future<void> closeTicket(String ticketId) async {
    try {
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Utiliser la fonction SQL pour fermer le ticket
      await client.rpc('close_ticket', params: {
        'ticket_uuid': ticketId,
        'admin_uuid': currentUser.id,
      });

      print('✅ [ADMIN] Ticket fermé définitivement: $ticketId');

    } catch (e) {
      print('❌ [ADMIN] Erreur fermeture ticket: $e');
      throw Exception('Erreur lors de la fermeture du ticket: $e');
    }
  }

  /// Récupère les statistiques des tickets
  static Future<Map<String, dynamic>> getTicketsStatistics() async {
    try {
      final response = await client
          .from('tickets_statistics')
          .select('*')
          .single();

      return response;
    } catch (e) {
      print('❌ [ADMIN] Erreur récupération statistiques: $e');
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  /// Récupère les tickets archivés avec conversation complète
  static Future<List<Map<String, dynamic>>> getArchivedTickets() async {
    try {
      final response = await client
          .from('tickets_archives')
          .select('*')
          .order('date_fermeture', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [ADMIN] Erreur récupération tickets archivés: $e');
      throw Exception('Erreur lors de la récupération des tickets archivés: $e');
    }
  }

  /// Vérifie si un ticket est fermé
  static Future<bool> isTicketClosed(String ticketId) async {
    try {
      final response = await client
          .from('tickets_support')
          .select('statut')
          .eq('id', ticketId)
          .single();

      return response['statut'] == 'closed';
    } catch (e) {
      print('❌ [ADMIN] Erreur vérification statut ticket: $e');
      return false;
    }
  }
}
