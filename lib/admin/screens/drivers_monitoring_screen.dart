import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/drivers_service.dart';
import '../services/positions_service.dart';

class DriversMonitoringScreen extends StatefulWidget {
  const DriversMonitoringScreen({super.key});

  @override
  State<DriversMonitoringScreen> createState() =>
      _DriversMonitoringScreenState();
}

class _DriversMonitoringScreenState extends State<DriversMonitoringScreen> {
  List<Map<String, dynamic>> drivers = [];
  Map<String, dynamic> stats = {};
  bool isLoading = true;
  List<Map<String, dynamic>> driverPositions = [];
  List<Map<String, dynamic>> clientPositions = [];
  final MapController _mapController = MapController();
  StreamSubscription<void>? _driversPosSub;
  StreamSubscription<void>? _clientsPosSub;
  LatLng _center = const LatLng(6.1375, 1.2123);
  bool _showSuspended = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadPositions();
    _driversPosSub = PositionsService.streamDriversPositions(() {
      _loadPositions();
    }).listen((_) {});
    // Clients realtime
    _loadClientsPositions();
    _clientsPosSub = PositionsService.streamClientsPositions(() {
      _loadClientsPositions();
    }).listen((_) {});
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final driversData = await DriversService.getAllDrivers();
      final statsData = await DriversService.getDriversStats();

      setState(() {
        drivers = driversData;
        stats = statsData;
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

  Future<void> _loadPositions() async {
    try {
      final rows = await PositionsService.getDriversPositions();
      if (!mounted) return;
      setState(() {
        driverPositions = rows;
      });
      // Center map to first available point
      if (rows.isNotEmpty) {
        final first = rows.first;
        final lat = (first['lat'] as num?)?.toDouble();
        final lng = (first['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          _center = LatLng(lat, lng);
          _mapController.move(_center, 12);
        }
      }
    } catch (_) {
      // ignore map loading errors silently
    }
  }

  Future<void> _loadClientsPositions() async {
    try {
      final rows = await PositionsService.getClientsPositions();
      if (!mounted) return;
      setState(() {
        clientPositions = rows;
      });
    } catch (_) {
      // ignore errors silently
    }
  }

  Future<void> _unsuspendDriver(String driverId) async {
    try {
      await DriversService.unsuspendDriver(driverId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le livreur a été réactivé.')),
      );
      await _loadData();
      await _loadPositions();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  void dispose() {
    _driversPosSub?.cancel();
    _clientsPosSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Surveillance des Livreurs'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Carte de surveillance (temps réel)
                Container(
                  height: 300,
                  margin: const EdgeInsets.all(16),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: 12,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.kolisa.admin',
                      ),
                      MarkerLayer(
                        markers: (() {
                          // Construire l'ensemble des IDs suspendus
                          final suspendedIds = drivers
                              .where((d) => (d['verified'] == false))
                              .map((d) => d['id'])
                              .toSet();
                          return driverPositions
                              .where(
                                (row) =>
                                    _showSuspended ||
                                    !suspendedIds.contains(row['user_id']),
                              )
                              .map((row) {
                                final lat = row['lat'];
                                final lng = row['lng'];
                                if (lat == null || lng == null) return null;
                                final online = (row['is_online'] == true);
                                final color = online
                                    ? Colors.blue
                                    : Colors.blueGrey;
                                return Marker(
                                  point: LatLng(
                                    (lat as num).toDouble(),
                                    (lng as num).toDouble(),
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: Tooltip(
                                    message:
                                        'Livreur${suspendedIds.contains(row['user_id']) ? ' (SUSPENDU)' : ''}\nOnline: ${online ? 'Oui' : 'Non'}\nLast seen: ${row['last_seen'] ?? ''}',
                                    child: Icon(
                                      Icons.location_on,
                                      size: 36,
                                      color: color,
                                    ),
                                  ),
                                );
                              })
                              .whereType<Marker>()
                              .toList();
                        })(),
                      ),
                      // Clients markers (from user_profiles)
                      MarkerLayer(
                        markers: clientPositions
                            .map((row) {
                              final lat = row['latitude'];
                              final lng = row['longitude'];
                              if (lat == null || lng == null) return null;
                              final online = (row['is_available'] == true);
                              final lastSeen = row['updated_at'];
                              final color = online ? Colors.green : Colors.teal;
                              return Marker(
                                point: LatLng(
                                  (lat as num).toDouble(),
                                  (lng as num).toDouble(),
                                ),
                                width: 36,
                                height: 36,
                                child: Tooltip(
                                  message:
                                      'Client\nDisponible: ${online ? 'Oui' : 'Non'}\nMis à jour: ${lastSeen ?? ''}',
                                  child: Icon(
                                    Icons.person_pin_circle,
                                    size: 32,
                                    color: color,
                                  ),
                                ),
                              );
                            })
                            .whereType<Marker>()
                            .toList(),
                      ),
                    ],
                  ),
                ),

                // Options d'affichage
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Switch(
                        value: _showSuspended,
                        onChanged: (v) => setState(() => _showSuspended = v),
                      ),
                      const SizedBox(width: 8),
                      const Text('Afficher les suspendus'),
                    ],
                  ),
                ),

                // Statistiques rapides
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total',
                          value: '${stats['total'] ?? 0}',
                          color: Colors.blue,
                          icon: Icons.people,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Disponibles',
                          value: '${stats['available'] ?? 0}',
                          color: Colors.green,
                          icon: Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'KYC Vérifiés',
                          value: '${stats['kyc_verified'] ?? 0}',
                          color: Colors.orange,
                          icon: Icons.verified_user,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Liste des livreurs
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: drivers
                        .where(
                          (d) => _showSuspended || (d['verified'] != false),
                        )
                        .length,
                    itemBuilder: (context, index) {
                      final visibleDrivers = drivers
                          .where(
                            (d) => _showSuspended || (d['verified'] != false),
                          )
                          .toList();
                      final driver = visibleDrivers[index];
                      return _DriverCard(
                        driver: driver,
                        onTap: () => context.push('/drivers/${driver['id']}'),
                        onUnsuspend: driver['verified'] == false
                            ? () => _unsuspendDriver(driver['id'])
                            : null,
                      );
                    },
                  ),
                ),
              ],
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
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  final VoidCallback onTap;
  final VoidCallback? onUnsuspend;

  const _DriverCard({
    required this.driver,
    required this.onTap,
    this.onUnsuspend,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = driver['is_available'] ?? false;
    final kycVerified = driver['kyc_verified'] ?? false;
    final verified = driver['verified'] != false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(isAvailable, kycVerified),
          child: Icon(
            _getStatusIcon(isAvailable, kycVerified),
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        title: Text(driver['fullname'] ?? driver['pseudo'] ?? 'Nom inconnu'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(driver['phone'] ?? 'Téléphone non disponible'),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _getLocationText(driver),
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
            if (kycVerified)
              Icon(Icons.verified, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            if (!verified && onUnsuspend != null)
              TextButton(
                onPressed: onUnsuspend,
                child: const Text('Réactiver'),
              ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: onTap,
            ),
          ],
        ),
        onTap: onTap,
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

  String _getLocationText(Map<String, dynamic> driver) {
    final lat = driver['latitude'];
    final lng = driver['longitude'];

    if (lat != null && lng != null) {
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
    return 'Position non disponible';
  }
}
