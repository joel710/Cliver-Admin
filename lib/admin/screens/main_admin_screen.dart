import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dashboard_screen.dart';
import 'drivers_monitoring_screen.dart';
import 'submissions_list_screen.dart';
import 'support_dashboard_screen.dart';
import 'settings_screen.dart';
import 'app_config_screen.dart';
import 'admin_alerts_screen.dart';
import 'audit_logs_screen.dart';
import 'promotions_management_screen.dart';
import 'subscription_grants_screen.dart';

class MainAdminScreen extends StatefulWidget {
  const MainAdminScreen({super.key});

  @override
  State<MainAdminScreen> createState() => _MainAdminScreenState();
}

class _MainAdminScreenState extends State<MainAdminScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const SubmissionsListScreen(),
    const DriversMonitoringScreen(),
    const SupportDashboardScreen(),
    const AppConfigScreen(),
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.dashboard,
      'title': 'Tableau de bord',
      'index': 0,
    },
    {
      'icon': Icons.verified_user,
      'title': 'KYC',
      'index': 1,
    },
    {
      'icon': Icons.local_shipping,
      'title': 'Livreurs',
      'index': 2,
    },
    {
      'icon': Icons.support_agent,
      'title': 'Support',
      'index': 3,
    },
    {
      'icon': Icons.settings_applications,
      'title': 'Configuration',
      'index': 4,
    },
  ];

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.of(context).pop(); // Fermer le drawer
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Kolisa Admin',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Navigation principale
                  ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    final item = _menuItems[index];
                    final isSelected = _currentIndex == item['index'];
                    
                    return ListTile(
                      leading: Icon(
                        item['icon'],
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      title: Text(
                        item['title'],
                        style: TextStyle(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      onTap: () => _changeTab(item['index']),
                    );
                  },
                ),
                
                const Divider(),
                
                // Section Actions rapides
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Actions rapides',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('Crash Reports'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/crash-reporting');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: const Text('Alertes Admin'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const AdminAlertsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Logs d\'Audit'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const AuditLogsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Clients'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/clients-monitor');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text('Carte'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/map-tracking');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text('Signalements'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/reports');
                  },
                ),
                
                const Divider(),
                
                // Section Promotions & Abonnements
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Promotions & Abonnements',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                ListTile(
                  leading: const Icon(Icons.local_offer),
                  title: const Text('Gestion des Promotions'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const PromotionsManagementScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.card_membership),
                  title: const Text('Attribution d\'Abonnements'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SubscriptionGrantsScreen()),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                const Divider(),
                
                // Paramètres
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Paramètres'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_menuItems[_currentIndex]['title']),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1,
      ),
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
    );
  }
}
