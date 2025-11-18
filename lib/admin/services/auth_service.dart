import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  static User? get currentUser => _client.auth.currentUser;

  static bool get isLoggedIn => _client.auth.currentUser != null;

  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final response = await _client
          .from('user_profiles')
          .select('*')
          .eq('id', user.id)
          .single();

      return response;
    } catch (e) {
      throw Exception('Erreur lors du chargement du profil: $e');
    }
  }

  static Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await _client
          .from('user_profiles')
          .update(updates)
          .eq('id', user.id);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }
}
