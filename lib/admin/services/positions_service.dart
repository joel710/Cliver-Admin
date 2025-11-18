import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class PositionsService {
  PositionsService._();
  static final SupabaseClient _client = Supabase.instance.client;

  // Fetch last known positions for drivers
  static Future<List<Map<String, dynamic>>> getDriversPositions() async {
    final rows = await _client
        .from('positions_livreurs')
        .select('user_id, lat, lng, accuracy, is_online, last_seen')
        .order('last_seen', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  // Fetch last known positions for clients
  static Future<List<Map<String, dynamic>>> getClientsPositions() async {
    // Pas de table positions_clients: utiliser user_profiles
    final rows = await _client
        .from('user_profiles')
        .select('id, latitude, longitude, is_available, updated_at, role, verified')
        .eq('role', 'client')
        .not('latitude', 'is', null)
        .not('longitude', 'is', null)
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  // Realtime stream for drivers positions (insert/update/delete)
  static Stream<void> streamDriversPositions(void Function() onChanged) {
    final controller = StreamController<void>();

    try {
      final channel = _client
          .channel('realtime:positions_livreurs')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'positions_livreurs',
            callback: (payload) {
              // notify UI
              if (!controller.isClosed) controller.add(null);
              onChanged();
            },
          )
          .subscribe();

      controller.onCancel = () async {
        await _client.removeChannel(channel);
        await controller.close();
      };
    } catch (e) {
      // En cas d'erreur, fermer le contrôleur
      controller.addError(e);
      controller.close();
    }

    return controller.stream;
  }

  // Realtime stream for clients positions
  static Stream<void> streamClientsPositions(void Function() onChanged) {
    final controller = StreamController<void>();

    try {
      final channel = _client
          .channel('realtime:user_profiles_clients')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'user_profiles',
            callback: (payload) {
              // On ne filtre pas côté serveur; on recharge côté client
              if (!controller.isClosed) controller.add(null);
              onChanged();
            },
          )
          .subscribe();

      controller.onCancel = () async {
        await _client.removeChannel(channel);
        await controller.close();
      };
    } catch (e) {
      // En cas d'erreur, fermer le contrôleur
      controller.addError(e);
      controller.close();
    }

    return controller.stream;
  }
}
