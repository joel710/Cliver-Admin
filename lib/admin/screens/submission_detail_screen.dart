import 'package:flutter/material.dart';
import '../services/supabase_admin_service.dart';
import '../services/kyc_repository.dart';
import '../widgets/decision_dialog.dart';
import '../widgets/kyc_status_chip.dart';

class SubmissionDetailScreen extends StatefulWidget {
  final String id;
  const SubmissionDetailScreen({super.key, required this.id});
  @override
  State<SubmissionDetailScreen> createState() => _SubmissionDetailScreenState();
}

class _SubmissionDetailScreenState extends State<SubmissionDetailScreen> {
  final repo = KycRepository();
  Map<String, dynamic>? sub;
  String? idFrontUrl, idBackUrl, selfieUrl;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final s = await SupabaseAdminService.getSubmission(widget.id);
      final front = await repo.signedUrl(s['id_front_path']);
      final back = await repo.signedUrl(s['id_back_path']);
      final selfie = await repo.signedUrl(s['selfie_path']);
      if (!mounted) return;
      setState(() {
        sub = s;
        idFrontUrl = front;
        idBackUrl = back;
        selfieUrl = selfie;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _decision(String type) async {
    final reason = await showDialog<String>(context: context, builder: (_) => DecisionDialog(type: type));
    if (reason == null && type != 'approve') return;
    setState(() => loading = true);
    try {
      if (type == 'approve') await repo.approve(widget.id);
      if (type == 'reject') await repo.reject(widget.id, reason ?? '');
      if (type == 'correction') await repo.requestCorrection(widget.id, reason ?? '');
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text('Erreur: $error')));
    }
    final s = sub!;
    final theme = Theme.of(context);
    final rawStatus = (s['status'] as String?);
    final mappedStatus = rawStatus == 'correction_required' ? 'correction_requested' : (rawStatus ?? 'pending');
    final isApproved = mappedStatus == 'approved';
    return Scaffold(
      appBar: AppBar(title: const Text('Détail KYC')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card: user + status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['user_profiles']?['fullname'] ?? s['user_id'],
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (s['user_profiles']?['phone'] != null) ...[
                      const SizedBox(height: 4),
                      Text(s['user_profiles']['phone'], style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                    ],
                    const SizedBox(height: 12),
                    Row(children: [
                      Text('Statut', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      KycStatusChip(status: mappedStatus),
                    ]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Documents card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Documents', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(children: [
                      if (idFrontUrl != null)
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(idFrontUrl!, height: 220, fit: BoxFit.cover),
                          ),
                        ),
                      if (idFrontUrl != null && idBackUrl != null) const SizedBox(width: 12),
                      if (idBackUrl != null)
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(idBackUrl!, height: 220, fit: BoxFit.cover),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 12),
                    if (selfieUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(selfieUrl!, height: 220, fit: BoxFit.cover),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Actions card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isApproved) ...[
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Cette demande est déjà approuvée.', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ElevatedButton.icon(
                          onPressed: isApproved ? null : () => _decision('approve'),
                          icon: const Icon(Icons.check),
                          label: const Text('Accepter'),
                        ),
                        OutlinedButton.icon(
                          onPressed: isApproved ? null : () => _decision('reject'),
                          icon: const Icon(Icons.close),
                          label: const Text('Refuser'),
                        ),
                        OutlinedButton.icon(
                          onPressed: isApproved ? null : () => _decision('correction'),
                          icon: const Icon(Icons.edit),
                          label: const Text('Demander correction'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
