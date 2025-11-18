import 'package:flutter/material.dart';
import '../services/clients_service.dart';
import '../services/user_blocks_service.dart';

class ClientProfileScreen extends StatefulWidget {
  final String id;
  const ClientProfileScreen({super.key, required this.id});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _history = const [];
  List<Map<String, dynamic>> _blocks = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);
      final p = await ClientsService.getClientProfile(widget.id);
      final h = await ClientsService.getClientMissionHistory(widget.id);
      final b = await UserBlocksService.getBlocksForUser(widget.id);
      if (!mounted) return;
      setState(() {
        _profile = p;
        _history = h;
        _blocks = b;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Client'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Profil introuvable'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _Header(profile: _profile!),
                      const SizedBox(height: 16),
                      
                      // Section Blocages
                      const Text('Blocages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_blocks.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Aucun blocage trouvé'),
                          ),
                        )
                      else
                        ..._blocks.map((block) => Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: block['source'] == 'user_blocks' ? Colors.orange : Colors.grey,
                                  child: Icon(
                                    block['source'] == 'user_blocks' ? Icons.block : Icons.report,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text('${block['blocker_name']} → ${block['blocked_name']}'),
                                subtitle: Text('${block['blocker_role']} bloque ${block['blocked_role']}'),
                                trailing: Chip(
                                  label: Text(block['source'] == 'user_blocks' ? 'Nouveau' : 'Ancien'),
                                  backgroundColor: block['source'] == 'user_blocks' ? Colors.orange[100] : Colors.grey[200],
                                ),
                              ),
                            )),
                      
                      const SizedBox(height: 16),
                      const Text('Historique des missions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_history.isEmpty)
                        const Text('Aucune mission trouvée')
                      else
                        ..._history.map((m) => Card(
                              child: ListTile(
                                title: Text(m['title'] ?? 'Mission'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Statut: ${m['status'] ?? '-'}'),
                                    if (m['created_at'] != null) Text('Créée: ${m['created_at']}'),
                                  ],
                                ),
                                trailing: Text('${m['prix'] ?? 0}'),
                              ),
                            )),
                    ],
                  ),
                ),
    );
  }
}

class _Header extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _Header({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(profile['fullname'] ?? 'Client', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(profile['phone'] ?? ''),
            const SizedBox(height: 8),
            Row(children: [
              Chip(
                label: const Text('Actif'), 
                backgroundColor: Colors.green[100],
              ),
            ]),
            const SizedBox(height: 8),
            const Text(
              'Note: Les blocages sont maintenant gérés via le système user_blocks',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
