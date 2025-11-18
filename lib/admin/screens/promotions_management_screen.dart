import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../services/promotions_service.dart';
import 'create_promotion_screen.dart';
import 'promotion_details_screen.dart';

class PromotionsManagementScreen extends StatefulWidget {
  const PromotionsManagementScreen({super.key});

  @override
  State<PromotionsManagementScreen> createState() => _PromotionsManagementScreenState();
}

class _PromotionsManagementScreenState extends State<PromotionsManagementScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  List<Map<String, dynamic>> _promotions = [];
  List<Map<String, dynamic>> _promotionsStats = [];
  Map<String, dynamic> _metrics = {};
  bool _isLoading = true;
  String _searchQuery = '';

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
        PromotionsService.getAllPromotions(),
        PromotionsService.getPromotionsStats(),
        PromotionsService.getPromotionsMetrics(),
      ]);
      
      if (mounted) {
        setState(() {
          _promotions = List<Map<String, dynamic>>.from(results[0] as List);
          _promotionsStats = List<Map<String, dynamic>>.from(results[1] as List);
          _metrics = results[2] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Erreur lors du chargement: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestion des Promotions',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Iconsax.percentage_circle), text: 'Promotions'),
            Tab(icon: Icon(Iconsax.chart_2), text: 'Statistiques'),
            Tab(icon: Icon(Iconsax.graph), text: 'Métriques'),
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
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPromotionsTab(),
                _buildStatsTab(),
                _buildMetricsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreatePromotion(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Iconsax.add),
        label: Text(
          'Nouvelle Promotion',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildPromotionsTab() {
    final filteredPromotions = _promotions.where((promo) {
      if (_searchQuery.isEmpty) return true;
      final name = (promo['name'] ?? '').toString().toLowerCase();
      final description = (promo['description'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
             description.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Barre de recherche
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher une promotion...',
              hintStyle: GoogleFonts.poppins(),
              prefixIcon: const Icon(Iconsax.search_normal),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        
        // Liste des promotions
        Expanded(
          child: filteredPromotions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredPromotions.length,
                  itemBuilder: (context, index) {
                    final promotion = filteredPromotions[index];
                    return _buildPromotionCard(promotion);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promotion) {
    final isActive = promotion['is_active'] == true;
    final expiresAt = promotion['expires_at'] != null 
        ? DateTime.parse(promotion['expires_at'])
        : null;
    final isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now());
    
    Color statusColor = Colors.grey;
    String statusText = 'Inactive';
    
    if (isActive && !isExpired) {
      statusColor = Colors.green;
      statusText = 'Active';
    } else if (isExpired) {
      statusColor = Colors.red;
      statusText = 'Expirée';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPromotionDetails(promotion),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getPromotionTypeColor(promotion['promotion_type']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getPromotionTypeIcon(promotion['promotion_type']),
                        color: _getPromotionTypeColor(promotion['promotion_type']),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            promotion['name'] ?? 'Promotion sans nom',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            _getPromotionTypeText(promotion['promotion_type']),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Description
                if (promotion['description'] != null) ...[
                  Text(
                    promotion['description'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Détails de la promotion
                Row(
                  children: [
                    _buildPromotionDetail(
                      icon: Iconsax.percentage_circle,
                      label: 'Valeur',
                      value: _getPromotionValue(promotion),
                    ),
                    const SizedBox(width: 16),
                    _buildPromotionDetail(
                      icon: Iconsax.people,
                      label: 'Cible',
                      value: _getTargetTypeText(promotion['target_type']),
                    ),
                    const SizedBox(width: 16),
                    _buildPromotionDetail(
                      icon: Iconsax.chart,
                      label: 'Utilisations',
                      value: '${promotion['current_uses'] ?? 0}${promotion['max_uses'] != null ? '/${promotion['max_uses']}' : ''}',
                    ),
                  ],
                ),
                
                if (expiresAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Iconsax.calendar,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Expire le ${DateFormat('dd/MM/yyyy à HH:mm').format(expiresAt)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _promotionsStats.length,
      itemBuilder: (context, index) {
        final stat = _promotionsStats[index];
        return _buildStatCard(stat);
      },
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat['name'] ?? 'Promotion',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(
                'Utilisations',
                '${stat['total_uses'] ?? 0}',
                Iconsax.chart,
                Colors.blue,
              ),
              _buildStatItem(
                'Réduction totale',
                '${(stat['total_discount_given'] ?? 0).toStringAsFixed(0)} XOF',
                Iconsax.money,
                Colors.green,
              ),
              _buildStatItem(
                'Statut',
                stat['status'] ?? 'Inconnu',
                Iconsax.info_circle,
                _getStatusColor(stat['status']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Métriques générales
          _buildMetricsGrid(),
          const SizedBox(height: 16),
          
          // Top promotions
          if (_metrics['top_promotions'] != null) ...[
            _buildTopPromotionsCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard(
          'Total Promotions',
          '${_metrics['total_promotions'] ?? 0}',
          Iconsax.percentage_circle,
          Colors.blue,
        ),
        _buildMetricCard(
          'Promotions Actives',
          '${_metrics['active_promotions'] ?? 0}',
          Iconsax.tick_circle,
          Colors.green,
        ),
        _buildMetricCard(
          'Promotions Expirées',
          '${_metrics['expired_promotions'] ?? 0}',
          Iconsax.close_circle,
          Colors.red,
        ),
        _buildMetricCard(
          'Réduction Totale',
          '${(_metrics['total_discount_given'] ?? 0).toStringAsFixed(0)} XOF',
          Iconsax.money,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopPromotionsCard() {
    final topPromotions = _metrics['top_promotions'] as List<dynamic>;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Promotions (30 derniers jours)',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...topPromotions.map((promo) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    promo['admin_promotions']['name'] ?? 'Promotion',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
                Text(
                  '${promo['count']} utilisations',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.percentage_circle,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune promotion trouvée',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre première promotion pour commencer',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes utilitaires
  Color _getPromotionTypeColor(String? type) {
    switch (type) {
      case 'percentage':
        return Colors.blue;
      case 'fixed_amount':
        return Colors.green;
      case 'free_subscription':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getPromotionTypeIcon(String? type) {
    switch (type) {
      case 'percentage':
        return Iconsax.percentage_circle;
      case 'fixed_amount':
        return Iconsax.money;
      case 'free_subscription':
        return Iconsax.gift;
      default:
        return Iconsax.discount_shape;
    }
  }

  String _getPromotionTypeText(String? type) {
    switch (type) {
      case 'percentage':
        return 'Pourcentage';
      case 'fixed_amount':
        return 'Montant fixe';
      case 'free_subscription':
        return 'Abonnement gratuit';
      default:
        return 'Inconnu';
    }
  }

  String _getTargetTypeText(String? type) {
    switch (type) {
      case 'all_users':
        return 'Tous les utilisateurs';
      case 'specific_users':
        return 'Utilisateurs spécifiques';
      case 'user_role':
        return 'Par rôle';
      case 'new_users':
        return 'Nouveaux utilisateurs';
      default:
        return 'Inconnu';
    }
  }

  String _getPromotionValue(Map<String, dynamic> promotion) {
    switch (promotion['promotion_type']) {
      case 'percentage':
        return '${promotion['discount_percentage']}%';
      case 'fixed_amount':
        return '${promotion['discount_amount']} XOF';
      case 'free_subscription':
        return 'Abonnement gratuit';
      default:
        return 'N/A';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'exhausted':
        return Colors.orange;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _navigateToCreatePromotion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePromotionScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  void _showPromotionDetails(Map<String, dynamic> promotion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PromotionDetailsScreen(
          promotionId: promotion['id'],
        ),
      ),
    );
  }
}
