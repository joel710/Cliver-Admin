import 'package:supabase_flutter/supabase_flutter.dart';

class CrashReportsService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getCrashReports({
    String? severity,
    String? status,
    int limit = 50,
  }) async {
    var query = _supabase
        .from('crash_reports')
        .select('*');

    if (severity != null && severity != 'all') {
      query = query.eq('severity', severity);
    }

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, int>> getCrashStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Total crashes
    final totalResponse = await _supabase
        .from('crash_reports')
        .select('id')
        .count(CountOption.exact);

    // Today's crashes
    final todayResponse = await _supabase
        .from('crash_reports')
        .select('id')
        .gte('created_at', startOfDay.toIso8601String())
        .count(CountOption.exact);

    // Resolved crashes
    final resolvedResponse = await _supabase
        .from('crash_reports')
        .select('id')
        .eq('status', 'resolved')
        .count(CountOption.exact);

    final total = totalResponse.count;
    final todayCount = todayResponse.count;
    final resolved = resolvedResponse.count;

    return {
      'total': total,
      'today': todayCount,
      'resolved': resolved,
      'resolvedRate': total > 0 ? ((resolved / total) * 100).round() : 0,
    };
  }

  static Future<void> updateCrashStatus(String id, String status, {String? resolution}) async {
    final updateData = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (status == 'resolved' && resolution != null) {
      updateData['resolution'] = resolution;
      updateData['resolved_at'] = DateTime.now().toIso8601String();
    }

    await _supabase
        .from('crash_reports')
        .update(updateData)
        .eq('id', id);
  }

  static Future<Map<String, dynamic>?> getCrashDetails(String id) async {
    final response = await _supabase
        .from('crash_reports')
        .select('*')
        .eq('id', id)
        .single();

    return response;
  }
}