import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../services/admin_alerts_service.dart';
import 'dart:async';

class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({super.key});

  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;
  
  List<Map<String, dynamic>> allAlerts = [];
  List<Map<String, dynamic>> unreadAlerts = [];
  List<Map<String, dynamic>> criticalAlerts = [];
  Map<String, dynamic> alertStats = {};
  bool isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAlerts();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _loadAlerts();
    });
  }

  Future<void> _loadAlerts() async {
    setState(() => isLoading = true);
    
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Charger toutes les alertes récentes
      final alertsData = await supabase
          .from('admin_alerts')
          .select('*')
          .order('created_at', ascending: false)
          .limit(200);

      final alerts = List<Map<String, dynamic>>.from(alertsData);

      // Charger les statistiques
      final stats = await AdminAlertsService.getAlertStats();

      if (mounted) {
        setState(() {
          allAlerts = alerts;
          unreadAlerts = alerts.where((alert) => !alert['is_read']).toList();
          criticalAlerts = alerts.where((alert) => 
            alert['severity'] == 'critical' || alert['severity'] == 'error'
          ).toList();
          alertStats = stats;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement alertes: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _markAsRead(String alertId) async {
    try {
      await AdminAlertsService.markAlertAsRead(alertId);
      _loadAlerts(); // Recharger les alertes
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alerte marquée comme lue'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur marquage alerte: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du marquage'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      for (final alert in unreadAlerts) {
        await AdminAlertsService.markAlertAsRead(alert['id']);
      }
      _loadAlerts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Toutes les alertes marquées comme lues'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur marquage toutes alertes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Alertes Admin',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Iconsax.refresh, color: isDark ? Colors.white : Colors.black),
            onPressed: _loadAlerts,
          ),
          if (unreadAlerts.isNotEmpty)
            IconButton(
              icon: Icon(Iconsax.tick_circle, color: const Color(0xFFFF7B31)),
              onPressed: _markAllAsRead,
              tooltip: 'Marquer tout comme lu',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF7B31),
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          indicatorColor: const Color(0xFFFF7B31),
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'Toutes (${allAlerts.length})'),
            Tab(text: 'Non lues (${unreadAlerts.length})'),
            Tab(text: 'Critiques (${criticalAlerts.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Statistiques rapides
          if (alertStats.isNotEmpty) _buildStatsHeader(isDark),

          // Contenu des onglets
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: const Color(0xFFFF7B31)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAlertsList(allAlerts, isDark),
                      _buildAlertsList(unreadAlerts, isDark),
                      _buildAlertsList(criticalAlerts, isDark),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques (7 derniers jours)',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  alertStats['total_last_week']?.toString() ?? '0',
                  Colors.blue,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Non lues',
                  alertStats['unread']?.toString() ?? '0',
                  Colors.orange,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Critiques',
                  (alertStats['by_severity']?['critical'] ?? 0).toString(),
                  Colors.red,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList(List<Map<String, dynamic>> alerts, bool isDark) {
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.notification,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune alerte',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _buildAlertCard(alert, isDark);
      },
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert, bool isDark) {
    final severity = alert['severity'] ?? 'info';
    final title = alert['title'] ?? '';
    final message = alert['message'] ?? '';
    final isRead = alert['is_read'] ?? false;
    final createdAt = DateTime.parse(alert['created_at']);
    final data = alert['data'] as Map<String, dynamic>? ?? {};

    Color severityColor;
    IconData severityIcon;
    
    switch (severity) {
      case 'critical':
        severityColor = Colors.red;
        severityIcon = Iconsax.danger;
        break;
      case 'error':
        severityColor = Colors.red[300]!;
        severityIcon = Iconsax.warning_2;
        break;
      case 'warning':
        severityColor = Colors.orange;
        severityIcon = Iconsax.info_circle;
        break;
      case 'info':
      default:
        severityColor = Colors.blue;
        severityIcon = Iconsax.notification;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isRead ? severityColor.withOpacity(0.3) : severityColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isRead ? null : () => _markAsRead(alert['id']),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête de l'alerte
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(severityIcon, color: severityColor, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            _formatTimestamp(createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: severityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            severity.toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: severityColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7B31),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Message de l'alerte
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    height: 1.4,
                  ),
                ),

                // Données supplémentaires
                if (data.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Détails:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...data.entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '${entry.key}: ${entry.value}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ],

                // Actions
                if (!isRead) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _markAsRead(alert['id']),
                        icon: Icon(Iconsax.tick_circle, size: 16),
                        label: Text('Marquer comme lu'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF7B31),
                          textStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
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

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }
}
