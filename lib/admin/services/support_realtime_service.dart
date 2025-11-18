import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupportRealtimeService {
  static final _supabase = Supabase.instance.client;
  static final Map<String, StreamSubscription> _subscriptions = {};

  /// Écoute les changements en temps réel sur les commentaires d'un ticket
  static Stream<List<Map<String, dynamic>>> listenToTicketComments(String ticketId) {
    return _supabase
        .from('commentaires_tickets')
        .stream(primaryKey: ['id'])
        .eq('ticket_id', ticketId)
        .order('date_creation', ascending: true)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Écoute les changements sur tous les tickets (pour le dashboard admin)
  static Stream<List<Map<String, dynamic>>> listenToAllTickets() {
    return _supabase
        .from('tickets_support')
        .stream(primaryKey: ['id'])
        .order('date_creation', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Écoute les tickets d'un utilisateur spécifique
  static Stream<List<Map<String, dynamic>>> listenToUserTickets(String userId) {
    return _supabase
        .from('tickets_support')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('date_creation', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Démarre l'écoute d'un ticket avec un callback
  static void startListening(String ticketId, Function(List<Map<String, dynamic>>) onUpdate) {
    // Arrêter l'écoute précédente si elle existe
    stopListening(ticketId);

    print('🔥 [ADMIN] Démarrage écoute real-time pour ticket: $ticketId');

    final subscription = listenToTicketComments(ticketId).listen(
      (comments) {
        print('🔥 [ADMIN] Nouveaux commentaires reçus: ${comments.length} commentaires');
        onUpdate(comments);
      },
      onError: (error) {
        print('❌ [ADMIN] Erreur real-time pour ticket $ticketId: $error');
      },
    );

    _subscriptions[ticketId] = subscription;
    print('✅ [ADMIN] Écoute real-time active pour ticket: $ticketId');
  }

  /// Arrête l'écoute d'un ticket spécifique
  static void stopListening(String ticketId) {
    _subscriptions[ticketId]?.cancel();
    _subscriptions.remove(ticketId);
  }

  /// Arrête toutes les écoutes
  static void stopAllListening() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// Vérifie si un ticket est en cours d'écoute
  static bool isListening(String ticketId) {
    return _subscriptions.containsKey(ticketId);
  }

  /// Obtient le nombre de connexions actives
  static int getActiveConnectionsCount() {
    return _subscriptions.length;
  }
}
