import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../services/vehicle_service.dart';
import '../../services/vehicle_analytics_service.dart';
import '../../widgets/network_image_widget.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _adminReport = {};
  List<Map<String, dynamic>> _livreurs = [];
  String _selectedVehicleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        VehicleAnalyticsService.getAdminVehicleReport(),
        _loadLivreurs(),
      ]);
      
      setState(() {
        _adminReport = results[0] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadLivreurs() async {
    try {
      // Simuler le chargement des livreurs depuis Supabase
      // En réalité, cela devrait être une requête à votre base de données
      _livreurs = [
        // Données d'exemple - remplacer par une vraie requête
      ];
      return _livreurs;
    } catch (e) {
      print('Erreur lors du chargement des livreurs: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Gestion des Véhicules',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Iconsax.chart_1), text: 'Statistiques'),
            Tab(icon: Icon(Iconsax.people), text: 'Livreurs'),
            Tab(icon: Icon(Iconsax.setting_2), text: 'Configuration'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStatisticsTab(),
                _buildLivreursTab(),
                _buildConfigurationTab(),
              ],
            ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement des données...'),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    if (_adminReport.isEmpty) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    final livreurDistribution = _adminReport['livreur_distribution'] as Map<String, dynamic>? ?? {};
    final summary = _adminReport['summary'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(summary),
          const SizedBox(height: 24),
          _buildVehicleDistributionChart(livreurDistribution),
          const SizedBox(height: 24),
          _buildVehicleMetricsTable(livreurDistribution),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Livreurs',
            value: '${summary['total_livreurs_with_vehicle'] ?? 0}',
            icon: Iconsax.people,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Types de Véhicules',
            value: '${summary['vehicle_types_count'] ?? 0}',
            icon: Iconsax.car,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Plus Populaire',
            value: summary['most_common_vehicle'] ?? 'N/A',
            icon: Iconsax.crown,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDistributionChart(Map<String, dynamic> distribution) {
    if (distribution.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribution des Véhicules',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...distribution.entries.map((entry) {
            final vehicleType = entry.key;
            final data = entry.value as Map<String, dynamic>;
            final totalLivreurs = data['total_livreurs'] as int;
            final vehicleInfo = VehicleService.getVehicleInfo(vehicleType);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildVehicleDistributionItem(
                vehicleType: vehicleType,
                vehicleInfo: vehicleInfo,
                count: totalLivreurs,
                maxCount: distribution.values
                    .map((v) => (v as Map<String, dynamic>)['total_livreurs'] as int)
                    .reduce((a, b) => a > b ? a : b),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVehicleDistributionItem({
    required String vehicleType,
    required VehicleInfo? vehicleInfo,
    required int count,
    required int maxCount,
  }) {
    final percentage = maxCount > 0 ? count / maxCount : 0.0;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: vehicleInfo?.color.withValues(alpha: 0.1) ?? Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            vehicleInfo?.icon ?? Iconsax.car,
            color: vehicleInfo?.color ?? Colors.grey,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicleInfo?.name ?? vehicleType,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: vehicleInfo?.color ?? Colors.grey,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: vehicleInfo?.color ?? Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleMetricsTable(Map<String, dynamic> distribution) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Métriques par Véhicule',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text('Véhicule', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Total', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Vérifiés', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Disponibles', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Note Moy.', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
              ],
              rows: distribution.entries.map((entry) {
                final vehicleType = entry.key;
                final data = entry.value as Map<String, dynamic>;
                final vehicleInfo = VehicleService.getVehicleInfo(vehicleType);
                
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            vehicleInfo?.icon ?? Iconsax.car,
                            color: vehicleInfo?.color ?? Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(vehicleInfo?.name ?? vehicleType),
                        ],
                      ),
                    ),
                    DataCell(Text('${data['total_livreurs']}')),
                    DataCell(Text('${data['verified_livreurs']}')),
                    DataCell(Text('${data['available_livreurs']}')),
                    DataCell(Text((data['average_rating'] as double).toStringAsFixed(1))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivreursTab() {
    return Column(
      children: [
        // Filtre par véhicule
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text(
                'Filtrer par véhicule:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedVehicleFilter,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('Tous')),
                    ...VehicleService.getAllVehicleTypes().map((type) {
                      final info = VehicleService.getVehicleInfo(type)!;
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(info.icon, size: 16, color: info.color),
                            const SizedBox(width: 8),
                            Text(info.name),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedVehicleFilter = value ?? 'all';
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Liste des livreurs
        Expanded(
          child: _livreurs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.people,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun livreur trouvé',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _livreurs.length,
                  itemBuilder: (context, index) {
                    final livreur = _livreurs[index];
                    return _buildLivreurCard(livreur);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLivreurCard(Map<String, dynamic> livreur) {
    final vehicleType = livreur['vehicle_type'] as String?;
    final vehicleInfo = vehicleType != null ? VehicleService.getVehicleInfo(vehicleType) : null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: livreur['avatar_url'] != null
                ? ClipOval(
                    child: NetworkImageWidget(
                      imageUrl: livreur['avatar_url'],
                      width: 48,
                      height: 48,
                    ),
                  )
                : Icon(
                    Iconsax.user,
                    color: Theme.of(context).colorScheme.primary,
                  ),
          ),
          
          const SizedBox(width: 16),
          
          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  livreur['fullname'] ?? 'Nom non défini',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  livreur['phone'] ?? 'Téléphone non défini',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (vehicleInfo != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: vehicleInfo.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          vehicleInfo.icon,
                          size: 14,
                          color: vehicleInfo.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vehicleInfo.name,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: vehicleInfo.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Statut
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: livreur['is_available'] == true
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  livreur['is_available'] == true ? 'Disponible' : 'Indisponible',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: livreur['is_available'] == true ? Colors.green : Colors.red,
                  ),
                ),
              ),
              if (livreur['kyc_verified'] == true) ...[
                const SizedBox(height: 4),
                Icon(
                  Iconsax.verify,
                  size: 16,
                  color: Colors.blue,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration du Système de Véhicules',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          
          // Types de véhicules supportés
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Types de Véhicules Supportés',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...VehicleService.getAllVehicleTypes().map((vehicleType) {
                  final info = VehicleService.getVehicleInfo(vehicleType)!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: info.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(info.icon, color: info.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                info.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${info.maxWeight.toInt()}kg • ${info.maxVolume.toInt()}L • ${info.basePriceMultiplier}x prix',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
