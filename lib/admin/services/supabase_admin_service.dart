import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAdminService {
  static final client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> listPending() async {
    final res = await client
        .from('livreur_kyc_submissions')
        .select('id,user_id,status,submitted_at')
        .eq('status', 'pending')
        .order('submitted_at', ascending: false);
    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> listAll() async {
    final res = await client.functions.invoke('kyc-admin-list');
    if (res.data is List) {
      return (res.data as List).cast<Map<String, dynamic>>();
    }
    throw Exception('kyc-admin-list: unexpected response ${res.data}');
  }

  static Future<Map<String, dynamic>> getSubmission(String id) async {
    final res = await client.functions.invoke('kyc-admin-get',
        body: {'id': id});
    if (res.data is Map<String, dynamic>) {
      return res.data as Map<String, dynamic>;
    }
    throw Exception('kyc-admin-get: unexpected response ${res.data}');
  }
}
