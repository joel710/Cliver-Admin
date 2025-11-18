import 'package:flutter/material.dart';
import '../services/drivers_service.dart';

class DriverProfileScreen extends StatefulWidget {
  final String id;

  const DriverProfileScreen({super.key, required this.id});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  Map<String, dynamic>? driver;
  Map<String, dynamic>? performanceStats;
  List<Map<String, dynamic>> missionHistory = [];
  List<Map<String, dynamic>> ratings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    try {
      setState(() {
        isLoading = true;
      });

      final driverData = await DriversService.getDriverProfile(widget.id);
      final performanceData = await DriversService.getDriverPerformanceStats(
        widget.id,
      );
      final historyData = await DriversService.getDriverMissionHistory(
        widget.id,
      );
      final ratingsData = await DriversService.getDriverRatings(widget.id);

      setState(() {
        driver = driverData;
        performanceStats = performanceData;
        missionHistory = historyData;
        ratings = ratingsData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (driver == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil du livreur')),
        body: const Center(child: Text('Livreur non trouvé')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil de ${driver!['fullname'] ?? driver!['pseudo']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.support_agent),
            onPressed: () => _showSupportDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du profil
            _ProfileHeader(driver: driver!),

            const SizedBox(height: 24),

            // Informations personnelles
            _InfoSection(
              title: 'Informations personnelles',
              children: [
                _InfoRow(
                  label: 'Nom complet',
                  value: driver!['fullname'] ?? 'N/A',
                ),
                _InfoRow(label: 'Pseudo', value: driver!['pseudo'] ?? 'N/A'),
                _InfoRow(label: 'Téléphone', value: driver!['phone'] ?? 'N/A'),
                _InfoRow(
                  label: 'Statut KYC',
                  value: driver!['kyc_verified'] ? 'Vérifié' : 'Non vérifié',
                ),
                _InfoRow(
                  label: 'Disponible',
                  value: driver!['is_available'] ? 'Oui' : 'Non',
                ),
                _InfoRow(
                  label: 'Solde wallet',
                  value: 'Non disponible',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Statistiques de performance
            if (performanceStats != null)
              _InfoSection(
                title: 'Performance',
                children: [
                  _InfoRow(
                    label: 'Missions totales',
                    value: '${performanceStats!['total_missions']}',
                  ),
                  _InfoRow(
                    label: 'Missions terminées',
                    value: '${performanceStats!['completed_missions']}',
                  ),
                  _InfoRow(
                    label: 'Taux de succès',
                    value:
                        '${performanceStats!['success_rate'].toStringAsFixed(1)}%',
                  ),
                  _InfoRow(
                    label: 'Note moyenne',
                    value:
                        '${performanceStats!['average_rating'].toStringAsFixed(1)}/5',
                  ),
                  _InfoRow(
                    label: 'Revenus totaux',
                    value:
                        '${performanceStats!['total_revenue'].toStringAsFixed(2)} Fcfa',
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Historique KYC
            _InfoSection(
              title: 'Historique KYC',
              children: [
                _InfoRow(
                  label: 'Vérifié le',
                  value: driver!['kyc_verified_at'] != null
                      ? DateTime.parse(
                          driver!['kyc_verified_at'],
                        ).toString().split(' ')[0]
                      : 'Non vérifié',
                ),
                _InfoRow(
                  label: 'Inscrit le',
                  value: driver!['created_at'] != null
                      ? DateTime.parse(
                          driver!['created_at'],
                        ).toString().split(' ')[0]
                      : 'N/A',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Actions rapides
            _ActionsSection(
              onContact: () => _contactDriver(context),
              onSuspend: () => _suspendDriver(context),
              onViewHistory: () => _viewMissionHistory(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: const Text(
          'Fonctionnalité à venir : modification du profil du livreur',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contacter le support'),
        content: const Text(
          'Fonctionnalité à venir : création d\'un ticket de support',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _contactDriver(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contacter le livreur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Appeler'),
              subtitle: Text(driver!['phone'] ?? 'N/A'),
              onTap: () {
                // TODO: Implémenter l'appel
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _suspendDriver(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspendre le livreur'),
        content: const Text('Êtes-vous sûr de vouloir suspendre ce livreur ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await DriversService.suspendDriver(
                  widget.id,
                  'Suspension administrative',
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Livreur suspendu avec succès')),
                );
                _loadDriverProfile(); // Recharger les données
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Suspendre'),
          ),
        ],
      ),
    );
  }

  void _viewMissionHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historique des missions'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: missionHistory.length,
            itemBuilder: (context, index) {
              final mission = missionHistory[index];
              return ListTile(
                title: Text(mission['title'] ?? 'Mission sans titre'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${mission['start_address']} → ${mission['end_address']}',
                    ),
                    Text('Prix: ${mission['prix']} Fcfa'),
                    Text('Statut: ${mission['status']}'),
                  ],
                ),
                trailing: Text(
                  mission['created_at'] != null
                      ? DateTime.parse(
                          mission['created_at'],
                        ).toString().split(' ')[0]
                      : 'N/A',
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> driver;

  const _ProfileHeader({required this.driver});

  @override
  Widget build(BuildContext context) {
    final isAvailable = driver['is_available'] ?? false;
    final kycVerified = driver['kyc_verified'] ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: _getStatusColor(isAvailable, kycVerified),
              child: Text(
                (driver['fullname'] ?? driver['pseudo'] ?? 'N/A')
                    .substring(0, 2)
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver['fullname'] ?? driver['pseudo'] ?? 'Nom inconnu',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(isAvailable, kycVerified),
                        color: _getStatusColor(isAvailable, kycVerified),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getStatusText(isAvailable, kycVerified),
                        style: TextStyle(
                          color: _getStatusColor(isAvailable, kycVerified),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getLocationText(driver),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(bool isAvailable, bool kycVerified) {
    if (!kycVerified) return Colors.red;
    if (isAvailable) return Colors.green;
    return Colors.orange;
  }

  IconData _getStatusIcon(bool isAvailable, bool kycVerified) {
    if (!kycVerified) return Icons.block;
    if (isAvailable) return Icons.check_circle;
    return Icons.pause_circle;
  }

  String _getStatusText(bool isAvailable, bool kycVerified) {
    if (!kycVerified) return 'KYC non vérifié';
    if (isAvailable) return 'Disponible';
    return 'Non disponible';
  }

  String _getLocationText(Map<String, dynamic> driver) {
    final lat = driver['latitude'];
    final lng = driver['longitude'];

    if (lat != null && lng != null) {
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
    return 'Position non disponible';
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsSection extends StatelessWidget {
  final VoidCallback onContact;
  final VoidCallback onSuspend;
  final VoidCallback onViewHistory;

  const _ActionsSection({
    required this.onContact,
    required this.onSuspend,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onContact,
                    icon: const Icon(Icons.contact_support),
                    label: const Text('Contacter'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onViewHistory,
                    icon: const Icon(Icons.history),
                    label: const Text('Historique'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSuspend,
                icon: const Icon(Icons.block),
                label: const Text('Suspendre'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
