import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/clients_service.dart';

class ClientsMonitorScreen extends StatefulWidget {
  const ClientsMonitorScreen({super.key});

  @override
  State<ClientsMonitorScreen> createState() => _ClientsMonitorScreenState();
}

class _ClientsMonitorScreenState extends State<ClientsMonitorScreen> {
  List<Map<String, dynamic>> _clients = [];
  bool _loading = true;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, online, offline, blocked

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      setState(() => _loading = true);
      final clients = await ClientsService.getClientsWithPresence();
      if (mounted) {
        setState(() {
          _clients = clients;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get _filteredClients {
    return _clients.where((client) {
      // Filtre par statut
      if (_filterStatus != 'all') {
        final isOnline = client['is_online'] == true;
        // Note: is_blocked n'existe plus, utiliser UserBlocksService pour vérifier les blocages
        final isBlocked = false; // Temporaire - à implémenter avec UserBlocksService

        switch (_filterStatus) {
          case 'online':
            if (!isOnline || isBlocked) return false;
            break;
          case 'offline':
            if (isOnline || isBlocked) return false;
            break;
          case 'blocked':
            // TODO: Implémenter avec UserBlocksService.areUsersBlocked
            return false; // Temporaire - filtrage des bloqués désactivé
        }
      }

      // Filtre par recherche
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = (client['fullname'] ?? '').toString().toLowerCase();
        final phone = (client['phone'] ?? '').toString().toLowerCase();

        if (!name.contains(query) && !phone.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _showClientActions(Map<String, dynamic> client) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ClientActionsSheet(client: client),
    );
  }

  void _showClientProfile(Map<String, dynamic> client) {
    // Navigation vers l'écran de profil client détaillé
    final id = client['id'] as String?;
    if (id != null && id.isNotEmpty) {
      context.push('/clients/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surveillance des Clients'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadClients),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Rechercher par nom ou téléphone...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Filtres de statut
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Tous',
                        isSelected: _filterStatus == 'all',
                        onTap: () => setState(() => _filterStatus = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'En ligne',
                        isSelected: _filterStatus == 'online',
                        onTap: () => setState(() => _filterStatus = 'online'),
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Hors ligne',
                        isSelected: _filterStatus == 'offline',
                        onTap: () => setState(() => _filterStatus = 'offline'),
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Bloqués',
                        isSelected: _filterStatus == 'blocked',
                        onTap: () => setState(() => _filterStatus = 'blocked'),
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Liste des clients
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClients.isEmpty
                ? const Center(child: Text('Aucun client trouvé'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = _filteredClients[index];
                      return _ClientCard(
                        client: client,
                        onTap: () => _showClientProfile(client),
                        onLongPress: () => _showClientActions(client),
                      );
                    },
                  ),
          ),
        ],
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

class _ClientCard extends StatelessWidget {
  final Map<String, dynamic> client;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ClientCard({
    required this.client,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = client['is_online'] == true;
    // Note: is_blocked n'existe plus, utiliser UserBlocksService pour vérifier les blocages
    final isBlocked = false; // Temporaire - à implémenter avec UserBlocksService

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getStatusColor(isOnline, isBlocked),
            child: Icon(
              _getStatusIcon(isOnline, isBlocked),
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          title: Text(client['fullname'] ?? 'Nom inconnu'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(client['phone'] ?? 'Téléphone non disponible'),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _getLocationText(client),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBlocked) Icon(Icons.block, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: onLongPress,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(bool isOnline, bool isBlocked) {
    if (isBlocked) return Colors.red;
    if (isOnline) return Colors.green;
    return Colors.grey;
  }

  IconData _getStatusIcon(bool isOnline, bool isBlocked) {
    if (isBlocked) return Icons.block;
    if (isOnline) return Icons.check_circle;
    return Icons.pause_circle;
  }

  String _getLocationText(Map<String, dynamic> client) {
    final lat = client['lat'];
    final lng = client['lng'];

    if (lat != null && lng != null) {
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
    return 'Position non disponible';
  }
}

class _ClientActionsSheet extends StatelessWidget {
  final Map<String, dynamic> client;

  const _ClientActionsSheet({required this.client});

  @override
  Widget build(BuildContext context) {
    // Note: is_blocked n'existe plus, utiliser UserBlocksService pour vérifier les blocages
    final isBlocked = false; // Temporaire - à implémenter avec UserBlocksService

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Voir le profil'),
            onTap: () {
              Navigator.pop(context);
              final id = client['id'] as String?;
              if (id != null && id.isNotEmpty) {
                context.push('/clients/$id');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Voir sur la carte'),
            onTap: () {
              Navigator.pop(context);
              context.push('/map-tracking');
            },
          ),
          ListTile(
            leading: Icon(isBlocked ? Icons.check_circle : Icons.block),
            title: const Text('Gérer les blocages'),
            onTap: () {
              Navigator.pop(context);
              _toggleClientBlock(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Créer un ticket de support'),
            onTap: () {
              Navigator.pop(context);
              _createSupportTicket(context);
            },
          ),
        ],
      ),
    );
  }

  void _toggleClientBlock(BuildContext context) async {
    // Rediriger vers l'écran de gestion des blocages
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Utilisez l\'écran "Gestion des Blocages" pour gérer les blocages utilisateur'),
      ),
    );
  }

  void _createSupportTicket(BuildContext context) {
    // Navigation vers le dashboard Support
    Navigator.pop(context);
    context.push('/support');
  }
}
