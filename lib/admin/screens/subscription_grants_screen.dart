import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../services/subscription_grants_service.dart';
import '../widgets/subscription_grant_dialog.dart';

class SubscriptionGrantsScreen extends StatefulWidget {
  const SubscriptionGrantsScreen({super.key});

  @override
  State<SubscriptionGrantsScreen> createState() => _SubscriptionGrantsScreenState();
}

class _SubscriptionGrantsScreenState extends State<SubscriptionGrantsScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  List<Map<String, dynamic>> _grants = [];
  Map<String, dynamic> _metrics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        SubscriptionGrantsService.getAllSubscriptionGrants(),
        SubscriptionGrantsService.getSubscriptionGrantsMetrics(),
      ]);
      
      if (mounted) {
        setState(() {
          _grants = List<Map<String, dynamic>>.from(results[0] as List);
          _metrics = results[1] as Map<String, dynamic>;
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attribution d\'Abonnements', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Iconsax.user_tick), text: 'Attributions'),
            Tab(icon: Icon(Iconsax.chart_2), text: 'Métriques'),
          ],
        ),
        actions: [IconButton(icon: const Icon(Iconsax.refresh), onPressed: _loadData)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildGrantsTab(), _buildMetricsTab()],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showGrantDialog,
        icon: const Icon(Iconsax.add),
        label: Text('Attribuer', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildGrantsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _grants.length,
      itemBuilder: (context, index) => _buildGrantCard(_grants[index]),
    );
  }

  Widget _buildGrantCard(Map<String, dynamic> grant) {
    final user = grant['user_profiles'];
    final plan = grant['subscription_plans'];
    final expiresAt = DateTime.parse(grant['expires_at']);
    final isExpired = expiresAt.isBefore(DateTime.now());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  (user?['fullname'] ?? 'U')[0].toUpperCase(),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?['fullname'] ?? 'Utilisateur', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    Text(user?['email'] ?? '', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isExpired ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isExpired ? 'Expiré' : 'Actif',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plan', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    Text(plan?['name'] ?? 'Plan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Durée', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    Text('${grant['duration_days']} jours', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expire le', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    Text(DateFormat('dd/MM/yy').format(expiresAt), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          if (grant['reason'] != null) ...[
            const SizedBox(height: 8),
            Text('Raison: ${grant['reason']}', style: GoogleFonts.poppins(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildMetricCard('Total', '${_metrics['total_grants'] ?? 0}', Iconsax.user_tick, Colors.blue),
              _buildMetricCard('Actifs', '${_metrics['active_grants'] ?? 0}', Iconsax.tick_circle, Colors.green),
              _buildMetricCard('Expirés', '${_metrics['expired_grants'] ?? 0}', Iconsax.close_circle, Colors.red),
              _buildMetricCard('Durée moy.', '${_metrics['avg_duration_days'] ?? 0} j', Iconsax.calendar, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
          Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  void _showGrantDialog() {
    showDialog(
      context: context,
      builder: (context) => SubscriptionGrantDialog(
        onGrantCreated: () {
          _loadData(); // Recharger les données après attribution
        },
      ),
    );
  }
}
