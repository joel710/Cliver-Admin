import 'package:supabase_flutter/supabase_flutter.dart';

class KycRepository {
  final _fn = Supabase.instance.client.functions;

  Future<void> approve(String submissionId) async {
    final res = await _fn.invoke('kyc-admin-approve', body: {
      'submission_id': submissionId,
    });
    if (res.status >= 400) {
      throw Exception('Approve failed (${res.status}): ${res.data?.toString() ?? 'Unknown error'}');
    }
  }

  Future<void> reject(String submissionId, String reason) async {
    final res = await _fn.invoke('kyc-admin-reject', body: {
      'submission_id': submissionId,
      'reason': reason,
    });
    if (res.status >= 400) {
      throw Exception('Reject failed (${res.status}): ${res.data?.toString() ?? 'Unknown error'}');
    }
  }

  Future<void> requestCorrection(String submissionId, String reason) async {
    final res = await _fn.invoke('kyc-admin-request-correction', body: {
      'submission_id': submissionId,
      'reason': reason,
    });
    if (res.status >= 400) {
      throw Exception('Request correction failed (${res.status}): ${res.data?.toString() ?? 'Unknown error'}');
    }
  }

  Future<String> signedUrl(String path, {int expiresIn = 3600}) async {
    final res = await _fn.invoke('kyc-admin-signed-url', body: {
      'path': path,
      'expiresIn': expiresIn,
    });
    if (res.status >= 400) {
      throw Exception('Signed URL failed (${res.status}): ${res.data?.toString() ?? 'Unknown error'}');
    }
    final data = res.data as Map<String, dynamic>;
    return (data['signedUrl'] as String?) ?? (data['signed_url'] as String);
  }
}
