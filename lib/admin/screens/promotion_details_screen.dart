import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../services/promotions_service.dart';

class PromotionDetailsScreen extends StatefulWidget {
  final String promotionId;

  const PromotionDetailsScreen({
    super.key,
    required this.promotionId,
  });

  @override
  State<PromotionDetailsScreen> createState() => _PromotionDetailsScreenState();
}

class _PromotionDetailsScreenState extends State<PromotionDetailsScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  Map<String, dynamic>? _promotion;
  List<Map<String, dynamic>> _usageHistory = [];
  List<Map<String, dynamic>> _targetUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPromotionDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPromotionDetails() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        PromotionsService.getPromotionById(widget.promotionId),
        PromotionsService.getPromotionUsageHistory(widget.promotionId),
        PromotionsService.getPromotionTargetUsers(widget.promotionId),
      ]);
      
      if (mounted) {
        setState(() {
          _promotion = results[0] as Map<String, dynamic>?;
          _usageHistory = List<Map<String, dynamic>>.from(results[1] as List);
          _targetUsers = List<Map<String, dynamic>>.from(results[2] as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _togglePromotionStatus() async {
    if (_promotion == null) return;

    try {
      final newStatus = !(_promotion!['is_active'] ?? false);
      await PromotionsService.updatePromotionStatus(widget.promotionId, newStatus);
      
      setState(() {
        _promotion!['is_active'] = newStatus;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'Promotion activée' : 'Promotion désactivée',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        title: Text(
          'Détails de la Promotion',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.arrow_left_2,
              color: Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
          ),
        ),
        actions: [
          if (_promotion != null)
            IconButton(
              onPressed: _togglePromotionStatus,
              icon: Icon(
                _promotion!['is_active'] == true ? Iconsax.pause : Iconsax.play,
                color: _promotion!['is_active'] == true ? Colors.orange : Colors.green,
              ),
              tooltip: _promotion!['is_active'] == true ? 'Désactiver' : 'Activer',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _promotion == null
              ? _buildErrorState()
              : Column(
                  children: [
                    // Header avec informations principales
                    _buildPromotionHeader(),
                    
                    // Tabs
                    Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: TabBar(
                        controller: _tabController,
                        labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                        unselectedLabelStyle: GoogleFonts.montserrat(),
                        tabs: const [
                          Tab(text: 'Détails'),
                          Tab(text: 'Utilisation'),
                          Tab(text: 'Utilisateurs'),
                        ],
                      ),
                    ),
                    
                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDetailsTab(),
                          _buildUsageTab(),
                          _buildUsersTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.close_circle,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Promotion non trouvée',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cette promotion n\'existe pas ou a été supprimée',
            style: GoogleFonts.montserrat(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionHeader() {
    final isActive = _promotion!['is_active'] == true;
    final isExpired = _promotion!['expires_at'] != null &&
        DateTime.parse(_promotion!['expires_at']).isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _promotion!['name'] ?? 'Promotion sans nom',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isExpired
                      ? Colors.red.withValues(alpha: 0.2)
                      : isActive
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isExpired
                        ? Colors.red
                        : isActive
                            ? Colors.green
                            : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Text(
                  isExpired
                      ? 'EXPIRÉE'
                      : isActive
                          ? 'ACTIVE'
                          : 'INACTIVE',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isExpired
                        ? Colors.red
                        : isActive
                            ? Colors.green
                            : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          
          if (_promotion!['description'] != null) ...[
            const SizedBox(height: 12),
            Text(
              _promotion!['description'],
              style: GoogleFonts.montserrat(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              _buildHeaderStat(
                'Type',
                _getPromotionTypeLabel(_promotion!['promotion_type']),
                Iconsax.tag,
              ),
              const SizedBox(width: 20),
              _buildHeaderStat(
                'Cible',
                _getTargetTypeLabel(_promotion!['target_type']),
                Iconsax.user_tag,
              ),
              const SizedBox(width: 20),
              _buildHeaderStat(
                'Utilisations',
                '${_promotion!['current_uses'] ?? 0}/${_promotion!['max_uses'] ?? '∞'}',
                Iconsax.chart,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard(
            'Informations générales',
            [
              _buildDetailRow('Nom', _promotion!['name']),
              _buildDetailRow('Description', _promotion!['description']),
              _buildDetailRow('Type de promotion', _getPromotionTypeLabel(_promotion!['promotion_type'])),
              _buildDetailRow('Type de cible', _getTargetTypeLabel(_promotion!['target_type'])),
              _buildDetailRow('Statut', _promotion!['is_active'] == true ? 'Active' : 'Inactive'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildDetailCard(
            'Paramètres de réduction',
            [
              if (_promotion!['discount_percentage'] != null)
                _buildDetailRow('Pourcentage de réduction', '${_promotion!['discount_percentage']}%'),
              if (_promotion!['discount_amount'] != null)
                _buildDetailRow('Montant de réduction', '${_promotion!['discount_amount']} FCFA'),
              if (_promotion!['free_subscription_plan_id'] != null)
                _buildDetailRow('Plan gratuit', 'Plan d\'abonnement offert'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildDetailCard(
            'Conditions et limites',
            [
              _buildDetailRow('Utilisations maximales', _promotion!['max_uses']?.toString() ?? 'Illimitées'),
              _buildDetailRow('Utilisations actuelles', _promotion!['current_uses']?.toString() ?? '0'),
              if (_promotion!['min_subscription_price'] != null)
                _buildDetailRow('Prix minimum d\'abonnement', '${_promotion!['min_subscription_price']} FCFA'),
              if (_promotion!['target_role'] != null)
                _buildDetailRow('Rôle ciblé', _promotion!['target_role']),
              if (_promotion!['expires_at'] != null)
                _buildDetailRow('Date d\'expiration', DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(_promotion!['expires_at']))),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildDetailCard(
            'Métadonnées',
            [
              _buildDetailRow('Créée le', DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(_promotion!['created_at']))),
              if (_promotion!['updated_at'] != null)
                _buildDetailRow('Modifiée le', DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(_promotion!['updated_at']))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Non défini',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: value != null 
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageTab() {
    return _usageHistory.isEmpty
        ? _buildEmptyState(
            icon: Iconsax.chart,
            title: 'Aucune utilisation',
            subtitle: 'Cette promotion n\'a pas encore été utilisée',
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _usageHistory.length,
            itemBuilder: (context, index) {
              final usage = _usageHistory[index];
              return _buildUsageCard(usage);
            },
          );
  }

  Widget _buildUsageCard(Map<String, dynamic> usage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(
                  Iconsax.user,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usage['user_profiles']?['fullname'] ?? 'Utilisateur inconnu',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (usage['user_profiles']?['email'] != null)
                      Text(
                        usage['user_profiles']['email'],
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(DateTime.parse(usage['used_at'])),
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          if (usage['discount_applied'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.discount_shape,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Réduction appliquée: ${usage['discount_applied']} FCFA',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return _targetUsers.isEmpty
        ? _buildEmptyState(
            icon: Iconsax.user_tag,
            title: 'Aucun utilisateur ciblé',
            subtitle: 'Cette promotion s\'applique à tous les utilisateurs',
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _targetUsers.length,
            itemBuilder: (context, index) {
              final user = _targetUsers[index];
              return _buildUserCard(user);
            },
          );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final roleColor = _getRoleColor(user['role']);
    final roleIcon = _getRoleIcon(user['role']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: roleColor.withValues(alpha: 0.1),
            child: Icon(roleIcon, color: roleColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['fullname'] ?? 'Nom non défini',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (user['email'] != null)
                  Text(
                    user['email'],
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              user['role']?.toUpperCase() ?? 'N/A',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: roleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getPromotionTypeLabel(String? type) {
    switch (type) {
      case 'percentage_discount':
        return 'Réduction en pourcentage';
      case 'fixed_discount':
        return 'Réduction fixe';
      case 'free_subscription':
        return 'Abonnement gratuit';
      default:
        return type ?? 'Type inconnu';
    }
  }

  String _getTargetTypeLabel(String? type) {
    switch (type) {
      case 'all_users':
        return 'Tous les utilisateurs';
      case 'specific_role':
        return 'Rôle spécifique';
      case 'specific_users':
        return 'Utilisateurs spécifiques';
      default:
        return type ?? 'Type inconnu';
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'livreur':
        return Colors.orange;
      case 'client':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'admin':
        return Iconsax.crown;
      case 'livreur':
        return Iconsax.truck;
      case 'client':
        return Iconsax.user;
      default:
        return Iconsax.profile_circle;
    }
  }
}
