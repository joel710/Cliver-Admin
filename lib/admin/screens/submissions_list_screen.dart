import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_admin_service.dart';
import '../widgets/kyc_status_chip.dart';

class SubmissionsListScreen extends StatefulWidget {
  const SubmissionsListScreen({super.key});
  @override
  State<SubmissionsListScreen> createState() => _SubmissionsListScreenState();
}

class _SubmissionsListScreenState extends State<SubmissionsListScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = SupabaseAdminService.listAll();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Demandes KYC')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 42, color: Colors.redAccent),
                    const SizedBox(height: 8),
                    Text('Erreur lors du chargement', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('${snap.error}', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                  ],
                ),
              ),
            );
          }
          final data = snap.data ?? [];
          if (data.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined, size: 42, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                    const SizedBox(height: 8),
                    Text('Aucune demande en attente', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('Les demandes KYC apparaîtront ici.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                  ],
                ),
              ),
            );
          }
          // Split into sections
          final active = data.where((row) {
            final st = (row['status'] as String?) ?? 'pending';
            final mapped = st == 'correction_required' ? 'correction_requested' : st;
            return mapped != 'approved';
          }).toList();
          final history = data.where((row) {
            final st = (row['status'] as String?) ?? 'pending';
            final mapped = st == 'correction_required' ? 'correction_requested' : st;
            return mapped == 'approved';
          }).toList();

          Widget buildItem(Map<String, dynamic> row) {
            final rawStatus = (row['status'] as String?) ?? 'pending';
            final mappedStatus = rawStatus == 'correction_required' ? 'correction_requested' : rawStatus;
            final profile = row['user_profiles'] as Map<String, dynamic>?;
            final fullname = (profile?['fullname'] as String?)?.trim();
            final pseudo = (profile?['pseudo'] as String?)?.trim();
            String title = fullname != null && fullname.isNotEmpty
                ? fullname
                : (row['user_id'] as String? ?? row['id'] as String);
            if (pseudo != null && pseudo.isNotEmpty) {
              title = '$title ($pseudo)';
            }
            final submittedAt = row['submitted_at'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/submissions/${row['id']}'),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.verified_user_outlined, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('Soumis le: $submittedAt', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        KycStatusChip(status: mappedStatus),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              if (active.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text('En cours', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                ),
                ...active.map(buildItem),
                const SizedBox(height: 12),
              ],
              if (history.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text('Historique', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                ),
                ...history.map(buildItem),
              ],
            ],
          );
        },
      ),
    );
  }
}
