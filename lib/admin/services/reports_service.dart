import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsService {
  static final _client = Supabase.instance.client;

  /// Récupère tous les signalements
  static Future<List<Map<String, dynamic>>> getAllReports() async {
    try {
      // 1. Récupérer les signalements
      final reports = await _client
          .from('user_reports')
          .select('*')
          .order('created_at', ascending: false);

      // 2. Récupérer les profils utilisateurs pour enrichir les données
      final userIds = <String>{};
      for (final report in reports) {
        userIds.add(report['reporter_id']);
        userIds.add(report['reported_user_id']);
      }

      final profiles = await _client
          .from('user_profiles')
          .select('id, fullname, avatar_url, phone, role')
          .inFilter('id', userIds.toList());

      // 3. Mapper les profils aux signalements
      final profilesMap = {for (final p in profiles) p['id']: p};
      
      return reports.map<Map<String, dynamic>>((report) => {
        ...report,
        'reporter': profilesMap[report['reporter_id']],
        'reported_user': profilesMap[report['reported_user_id']],
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des signalements: $e');
    }
  }

  /// Récupère les signalements par statut
  static Future<List<Map<String, dynamic>>> getReportsByStatus(
    String status,
  ) async {
    try {
      // 1. Récupérer les signalements par statut
      final reports = await _client
          .from('user_reports')
          .select('*')
          .eq('status', status)
          .order('created_at', ascending: false);

      // 2. Récupérer les profils utilisateurs pour enrichir les données
      final userIds = <String>{};
      for (final report in reports) {
        userIds.add(report['reporter_id']);
        userIds.add(report['reported_user_id']);
      }

      if (userIds.isEmpty) return [];

      final profiles = await _client
          .from('user_profiles')
          .select('id, fullname, avatar_url, phone, role')
          .inFilter('id', userIds.toList());

      // 3. Mapper les profils aux signalements
      final profilesMap = {for (final p in profiles) p['id']: p};
      
      return reports.map<Map<String, dynamic>>((report) => {
        ...report,
        'reporter': profilesMap[report['reporter_id']],
        'reported_user': profilesMap[report['reported_user_id']],
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des signalements: $e');
    }
  }

  /// Met à jour le statut d'un signalement
  static Future<void> updateReportStatus(
    String reportId,
    String status,
    String adminNotes,
  ) async {
    try {
      await _client
          .from('user_reports')
          .update({
            'status': status,
            'admin_notes': adminNotes,
            'resolved_at': status == 'resolved'
                ? DateTime.now().toIso8601String()
                : null,
          })
          .eq('id', reportId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  /// Récupère les statistiques des signalements
  static Future<Map<String, dynamic>> getReportsStats() async {
    try {
      final totalReports = await _client.from('user_reports').select('id');

      final pendingReports = await _client
          .from('user_reports')
          .select('id')
          .eq('status', 'pending');

      final resolvedReports = await _client
          .from('user_reports')
          .select('id')
          .eq('status', 'resolved');

      final urgentReports = await _client
          .from('user_reports')
          .select('id')
          .eq('status', 'urgent');

      return {
        'total': totalReports.length,
        'pending': pendingReports.length,
        'resolved': resolvedReports.length,
        'urgent': urgentReports.length,
      };
    } catch (e) {
      throw Exception('Erreur lors du chargement des statistiques: $e');
    }
  }

  /// Cette méthode est obsolète - utiliser UserBlocksService à la place
  @deprecated
  static Future<void> blockReportedUser(
    String reportedUserId,
    String reason,
  ) async {
    throw Exception('Méthode obsolète - utiliser UserBlocksService pour gérer les blocages');
  }

  /// Récupère l'historique des signalements d'un utilisateur
  static Future<List<Map<String, dynamic>>> getUserReportsHistory(
    String userId,
  ) async {
    try {
      final res = await _client
          .from('user_reports')
          .select('''
            id,
            reason,
            description,
            status,
            created_at,
            resolved_at,
            admin_notes
          ''')
          .or('reporter_id.eq.$userId,reported_user_id.eq.$userId')
          .order('created_at', ascending: false);

      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Erreur lors du chargement de l\'historique: $e');
    }
  }
}
