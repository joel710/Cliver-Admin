import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/positions_service.dart';

class MapTrackingScreen extends StatefulWidget {
  const MapTrackingScreen({super.key});

  @override
  State<MapTrackingScreen> createState() => _MapTrackingScreenState();
}

class _MapTrackingScreenState extends State<MapTrackingScreen> {
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _clients = [];
  StreamSubscription<void>? _driversSub;
  StreamSubscription<void>? _clientsSub;
  bool _loading = true;
  LatLng _center = const LatLng(6.1375, 1.2123);

  @override
  void initState() {
    super.initState();
    _loadAll();
    _driversSub = PositionsService.streamDriversPositions(() {
      _refreshDrivers();
    }).listen((_) {});
    _clientsSub = PositionsService.streamClientsPositions(() {
      _refreshClients();
    }).listen((_) {});
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([_refreshDrivers(), _refreshClients()]);
    // Center map to first available point
    final LatLng? first = _firstPoint();
    if (first != null) {
      _mapController.move(first, 12);
      _center = first;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refreshDrivers() async {
    final list = await PositionsService.getDriversPositions();
    if (!mounted) return;
    setState(() => _drivers = list);
  }

  Future<void> _refreshClients() async {
    final list = await PositionsService.getClientsPositions();
    if (!mounted) return;
    setState(() => _clients = list);
  }

  LatLng? _firstPoint() {
    if (_drivers.isNotEmpty) {
      final lat = _drivers.first['lat'];
      final lng = _drivers.first['lng'];
      if (lat != null && lng != null) {
        return LatLng(
          (lat as num).toDouble(),
          (lng as num).toDouble(),
        );
      }
    }
    if (_clients.isNotEmpty) {
      final lat = _clients.first['lat'];
      final lng = _clients.first['lng'];
      if (lat != null && lng != null) {
        return LatLng(
          (lat as num).toDouble(),
          (lng as num).toDouble(),
        );
      }
    }
    return null;
  }

  @override
  void dispose() {
    _driversSub?.cancel();
    _clientsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      ..._drivers
          .map((d) => _markerFromRow(d, isDriver: true))
          .whereType<Marker>(),
      ..._clients
          .map((c) => _markerFromRow(c, isDriver: false))
          .whereType<Marker>(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte - Localisation (Livreurs & Clients)'),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir',
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: _center, initialZoom: 12),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.kolisa.admin',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
      bottomNavigationBar: _buildLegend(),
    );
  }

  Marker? _markerFromRow(Map<String, dynamic> row, {required bool isDriver}) {
    final lat = row['lat'];
    final lng = row['lng'];
    if (lat == null || lng == null) return null;
    final online = (row['is_online'] == true);
    final color = online
        ? (isDriver ? Colors.blue : Colors.green)
        : (isDriver ? Colors.blueGrey : Colors.grey);

    return Marker(
      point: LatLng((lat as num).toDouble(), (lng as num).toDouble()),
      width: 40,
      height: 40,
      child: Tooltip(
        message:
            '${isDriver ? 'Livreur' : 'Client'}\nOnline: ${online ? 'Oui' : 'Non'}\nLast seen: ${row['last_seen'] ?? ''}',
        child: Icon(Icons.location_on, size: 36, color: color),
      ),
    );
  }

  Widget _buildLegend() {
    Widget item(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, color: color, size: 18),
        const SizedBox(width: 4),
        Text(label),
      ],
    );

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          item(Colors.blue, 'Livreur online'),
          item(Colors.blueGrey, 'Livreur offline'),
          item(Colors.green, 'Client online'),
          item(Colors.grey, 'Client offline'),
        ],
      ),
    );
  }
}
