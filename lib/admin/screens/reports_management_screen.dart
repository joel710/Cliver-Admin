import 'package:flutter/material.dart';
import '../services/reports_service.dart';

class ReportsManagementScreen extends StatefulWidget {
  const ReportsManagementScreen({super.key});

  @override
  State<ReportsManagementScreen> createState() =>
      _ReportsManagementScreenState();
}

class _ReportsManagementScreenState extends State<ReportsManagementScreen> {
  List<Map<String, dynamic>> _reports = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loading = true);
      await Future.wait([_loadReports(), _loadStats()]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadReports() async {
    final reports = _filterStatus == 'all'
        ? await ReportsService.getAllReports()
        : await ReportsService.getReportsByStatus(_filterStatus);

    if (mounted) {
      setState(() => _reports = reports);
    }
  }

  Future<void> _loadStats() async {
    final stats = await ReportsService.getReportsStats();
    if (mounted) {
      setState(() => _stats = stats);
    }
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => _ReportDetailsDialog(
        report: report,
        onStatusUpdate: (status, notes) async {
          await _updateReportStatus(report['id'], status, notes);
        },
      ),
    );
  }

  Future<void> _updateReportStatus(
    String reportId,
    String status,
    String notes,
  ) async {
    try {
      await ReportsService.updateReportStatus(reportId, status, notes);
      Navigator.pop(context);
      _loadData(); // Recharger les données

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statut mis à jour avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Signalements'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistiques
                _buildStatsCards(),

                // Filtres
                _buildFilters(),

                // Liste des signalements
                Expanded(
                  child: _reports.isEmpty
                      ? const Center(child: Text('Aucun signalement trouvé'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _reports.length,
                          itemBuilder: (context, index) {
                            final report = _reports[index];
                            return _ReportCard(
                              report: report,
                              onTap: () => _showReportDetails(report),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Total',
              value: '${_stats['total'] ?? 0}',
              color: Colors.blue,
              icon: Icons.report,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: 'En attente',
              value: '${_stats['pending'] ?? 0}',
              color: Colors.orange,
              icon: Icons.pending,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: 'Urgents',
              value: '${_stats['urgent'] ?? 0}',
              color: Colors.red,
              icon: Icons.priority_high,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: 'Résolus',
              value: '${_stats['resolved'] ?? 0}',
              color: Colors.green,
              icon: Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Tous',
              isSelected: _filterStatus == 'all',
              onTap: () {
                setState(() => _filterStatus = 'all');
                _loadReports();
              },
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'En attente',
              isSelected: _filterStatus == 'pending',
              onTap: () {
                setState(() => _filterStatus = 'pending');
                _loadReports();
              },
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Urgents',
              isSelected: _filterStatus == 'urgent',
              onTap: () {
                setState(() => _filterStatus = 'urgent');
                _loadReports();
              },
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Résolus',
              isSelected: _filterStatus == 'resolved',
              onTap: () {
                setState(() => _filterStatus = 'resolved');
                _loadReports();
              },
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color?.withOpacity(0.3),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = report['status'] ?? 'pending';
    final reporter = report['reporter'] ?? {};
    final reportedUser = report['reported_user'] ?? {};
    final reason = report['reason'] ?? 'Raison non spécifiée';
    final createdAt = report['created_at'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Signalement de ${reporter['fullname'] ?? 'Utilisateur'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _StatusChip(status: status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Signalé: ${reportedUser['fullname'] ?? 'Utilisateur inconnu'}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text('Raison: $reason', style: const TextStyle(fontSize: 14)),
              if (createdAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Signalé le: ${_formatDate(createdAt)}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'urgent':
        return Icons.priority_high;
      case 'pending':
        return Icons.pending;
      case 'resolved':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'urgent':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Date inconnue';
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'urgent':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'urgent':
        return 'URGENT';
      case 'pending':
        return 'EN ATTENTE';
      case 'resolved':
        return 'RÉSOLU';
      default:
        return status.toUpperCase();
    }
  }
}

class _ReportDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> report;
  final Function(String, String) onStatusUpdate;

  const _ReportDetailsDialog({
    required this.report,
    required this.onStatusUpdate,
  });

  @override
  State<_ReportDetailsDialog> createState() => _ReportDetailsDialogState();
}

class _ReportDetailsDialogState extends State<_ReportDetailsDialog> {
  String _selectedStatus = 'pending';
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final status = widget.report['status'];
    // Vérifier que le statut est valide, sinon utiliser 'pending'
    if (status == 'pending' || status == 'urgent' || status == 'resolved') {
      _selectedStatus = status;
    } else {
      _selectedStatus = 'pending';
    }
    _notesController.text = widget.report['admin_notes'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final reporter = widget.report['reporter'] ?? {};
    final reportedUser = widget.report['reported_user'] ?? {};

    return AlertDialog(
      title: const Text('Détails du Signalement'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _InfoRow(
              label: 'Signalé par:',
              value:
                  '${reporter['fullname'] ?? 'N/A'} (${reporter['role'] ?? 'N/A'})',
            ),
            _InfoRow(
              label: 'Utilisateur signalé:',
              value:
                  '${reportedUser['fullname'] ?? 'N/A'} (${reportedUser['role'] ?? 'N/A'})',
            ),
            _InfoRow(label: 'Raison:', value: widget.report['reason'] ?? 'N/A'),
            _InfoRow(
              label: 'Description:',
              value: widget.report['description'] ?? 'Aucune description',
            ),
            _InfoRow(
              label: 'Date:',
              value: _formatDate(widget.report['created_at']),
            ),
            const SizedBox(height: 16),
            const Text(
              'Statut:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('En attente')),
                DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                DropdownMenuItem(value: 'resolved', child: Text('Résolu')),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value!);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Notes admin:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ajouter des notes...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onStatusUpdate(_selectedStatus, _notesController.text);
          },
          child: const Text('Mettre à jour'),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Date inconnue';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
