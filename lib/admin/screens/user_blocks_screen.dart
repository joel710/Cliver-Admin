import 'package:flutter/material.dart';
import '../services/user_blocks_service.dart';

class UserBlocksScreen extends StatefulWidget {
  const UserBlocksScreen({super.key});

  @override
  State<UserBlocksScreen> createState() => _UserBlocksScreenState();
}

class _UserBlocksScreenState extends State<UserBlocksScreen> {
  List<Map<String, dynamic>> _blocks = [];
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String _filterSource = 'all'; // all, user_blocks, user_reports

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loading = true);
      final blocks = await UserBlocksService.getAllBlocks();
      final stats = await UserBlocksService.getBlocksStats();
      
      if (mounted) {
        setState(() {
          _blocks = blocks;
          _stats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredBlocks {
    if (_filterSource == 'all') return _blocks;
    return _blocks.where((block) => block['source'] == _filterSource).toList();
  }

  Future<void> _removeBlock(Map<String, dynamic> block) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le déblocage'),
        content: Text(
          'Voulez-vous débloquer ${block['blocked_name']} pour ${block['blocker_name']} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Débloquer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await UserBlocksService.removeBlock(
          block['blocker_id'],
          block['blocked_id'],
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Blocage supprimé avec succès')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Blocages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistiques
                if (_stats != null) _StatsCard(stats: _stats!),
                
                // Filtres
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('Source: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'all', label: Text('Tous')),
                            ButtonSegment(value: 'user_blocks', label: Text('Nouveaux')),
                            ButtonSegment(value: 'user_reports', label: Text('Anciens')),
                          ],
                          selected: {_filterSource},
                          onSelectionChanged: (Set<String> selection) {
                            setState(() {
                              _filterSource = selection.first;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Liste des blocages
                Expanded(
                  child: _filteredBlocks.isEmpty
                      ? const Center(child: Text('Aucun blocage trouvé'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredBlocks.length,
                          itemBuilder: (context, index) {
                            final block = _filteredBlocks[index];
                            return _BlockCard(
                              block: block,
                              onRemove: () => _removeBlock(block),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques des Blocages',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Blocages Actifs',
                  value: '${stats['total_blocks'] ?? 0}',
                  color: Colors.orange,
                ),
                _StatItem(
                  label: 'Anciens Signalements',
                  value: '${stats['old_reports'] ?? 0}',
                  color: Colors.grey,
                ),
                _StatItem(
                  label: 'Utilisateurs Bloqués',
                  value: '${stats['unique_blocked_users'] ?? 0}',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BlockCard extends StatelessWidget {
  final Map<String, dynamic> block;
  final VoidCallback onRemove;

  const _BlockCard({
    required this.block,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isNewSystem = block['source'] == 'user_blocks';
    final createdAt = DateTime.tryParse(block['created_at'] ?? '');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isNewSystem ? Colors.orange : Colors.grey,
          child: Icon(
            isNewSystem ? Icons.block : Icons.report,
            color: Colors.white,
          ),
        ),
        title: Text('${block['blocker_name']} → ${block['blocked_name']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${block['blocker_role']} bloque ${block['blocked_role']}'),
            if (createdAt != null)
              Text(
                'Le ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(isNewSystem ? 'Nouveau' : 'Ancien'),
              backgroundColor: isNewSystem ? Colors.orange[100] : Colors.grey[200],
              labelStyle: TextStyle(
                color: isNewSystem ? Colors.orange[800] : Colors.grey[800],
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            if (isNewSystem)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onRemove,
                tooltip: 'Supprimer le blocage',
              ),
          ],
        ),
      ),
    );
  }
}
