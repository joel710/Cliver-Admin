import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;
  
  List<Map<String, dynamic>> allLogs = [];
  List<Map<String, dynamic>> userLogs = [];
  List<Map<String, dynamic>> missionLogs = [];
  List<Map<String, dynamic>> systemLogs = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedSeverity = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => isLoading = true);
    
    try {
      // Charger tous les logs récents
      final logsData = await supabase
          .from('audit_logs')
          .select('''
            id, action, entity_type, entity_id, user_id, ip_address,
            user_agent, details, severity, created_at,
            user:user_id(fullname, role)
          ''')
          .order('created_at', ascending: false)
          .limit(500);

      final logs = List<Map<String, dynamic>>.from(logsData);

      if (mounted) {
        setState(() {
          allLogs = logs;
          userLogs = logs.where((log) => log['entity_type'] == 'user').toList();
          missionLogs = logs.where((log) => log['entity_type'] == 'mission').toList();
          systemLogs = logs.where((log) => log['entity_type'] == 'system').toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur logs: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _createLog(String action, String entityType, String entityId, 
      Map<String, dynamic> details, {String severity = 'info'}) async {
    try {
      await supabase.from('audit_logs').insert({
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'user_id': supabase.auth.currentUser?.id,
        'details': details,
        'severity': severity,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Erreur création log: $e');
    }
  }

  List<Map<String, dynamic>> _filterLogs(List<Map<String, dynamic>> logs) {
    var filtered = logs;
    
    // Filtrer par recherche
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((log) {
        final action = log['action']?.toString().toLowerCase() ?? '';
        final details = log['details']?.toString().toLowerCase() ?? '';
        final userName = log['user']?['fullname']?.toString().toLowerCase() ?? '';
        final query = searchQuery.toLowerCase();
        return action.contains(query) || details.contains(query) || userName.contains(query);
      }).toList();
    }
    
    // Filtrer par sévérité
    if (selectedSeverity != 'all') {
      filtered = filtered.where((log) => log['severity'] == selectedSeverity).toList();
    }
    
    return filtered;
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
          'Logs d\'Audit',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Iconsax.refresh, color: isDark ? Colors.white : Colors.black),
            onPressed: _loadLogs,
          ),
          PopupMenuButton<String>(
            icon: Icon(Iconsax.filter, color: isDark ? Colors.white : Colors.black),
            onSelected: (value) {
              setState(() => selectedSeverity = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text('Tous les niveaux')),
              PopupMenuItem(value: 'info', child: Text('Info')),
              PopupMenuItem(value: 'warning', child: Text('Avertissement')),
              PopupMenuItem(value: 'error', child: Text('Erreur')),
              PopupMenuItem(value: 'critical', child: Text('Critique')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF7B31),
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          indicatorColor: const Color(0xFFFF7B31),
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          isScrollable: true,
          tabs: [
            Tab(text: 'Tous (${allLogs.length})'),
            Tab(text: 'Utilisateurs (${userLogs.length})'),
            Tab(text: 'Missions (${missionLogs.length})'),
            Tab(text: 'Système (${systemLogs.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Rechercher dans les logs...',
                hintStyle: GoogleFonts.poppins(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                prefixIcon: Icon(
                  Iconsax.search_normal,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          // Contenu des onglets
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: const Color(0xFFFF7B31)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLogsList(_filterLogs(allLogs), isDark),
                      _buildLogsList(_filterLogs(userLogs), isDark),
                      _buildLogsList(_filterLogs(missionLogs), isDark),
                      _buildLogsList(_filterLogs(systemLogs), isDark),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(List<Map<String, dynamic>> logs, bool isDark) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.document,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun log trouvé',
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
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildLogCard(log, isDark);
      },
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log, bool isDark) {
    final severity = log['severity'] ?? 'info';
    final action = log['action'] ?? '';
    final entityType = log['entity_type'] ?? '';
    final user = log['user'];
    final createdAt = DateTime.parse(log['created_at']);
    final details = log['details'] as Map<String, dynamic>? ?? {};

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
        severityIcon = Iconsax.document;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: severityColor, width: 4)),
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
          // En-tête du log
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
                      _getActionText(action, entityType),
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
            ],
          ),

          const SizedBox(height: 12),

          // Informations utilisateur
          if (user != null) ...[
            Row(
              children: [
                Icon(
                  Iconsax.user,
                  size: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  '${user['fullname']} (${user['role']})',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Détails du log
          if (details.isNotEmpty) ...[
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
                  ...details.entries.map((entry) => Padding(
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

          // Informations techniques
          if (log['ip_address'] != null || log['user_agent'] != null) ...[
            const SizedBox(height: 8),
            ExpansionTile(
              title: Text(
                'Informations techniques',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              children: [
                if (log['ip_address'] != null)
                  _buildTechnicalInfo('Adresse IP', log['ip_address'], isDark),
                if (log['user_agent'] != null)
                  _buildTechnicalInfo('User Agent', log['user_agent'], isDark),
                _buildTechnicalInfo('ID Entité', log['entity_id'] ?? 'N/A', isDark),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTechnicalInfo(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getActionText(String action, String entityType) {
    final entityText = _getEntityText(entityType);
    
    switch (action) {
      case 'create':
        return 'Création de $entityText';
      case 'update':
        return 'Modification de $entityText';
      case 'delete':
        return 'Suppression de $entityText';
      case 'login':
        return 'Connexion utilisateur';
      case 'logout':
        return 'Déconnexion utilisateur';
      case 'block':
        return 'Blocage d\'utilisateur';
      case 'unblock':
        return 'Déblocage d\'utilisateur';
      case 'assign':
        return 'Attribution de mission';
      case 'complete':
        return 'Finalisation de mission';
      case 'cancel':
        return 'Annulation de mission';
      case 'report':
        return 'Signalement créé';
      case 'resolve_report':
        return 'Résolution de signalement';
      case 'payment':
        return 'Paiement effectué';
      case 'refund':
        return 'Remboursement traité';
      default:
        return action;
    }
  }

  String _getEntityText(String entityType) {
    switch (entityType) {
      case 'user':
        return 'utilisateur';
      case 'mission':
        return 'mission';
      case 'payment':
        return 'paiement';
      case 'report':
        return 'signalement';
      case 'system':
        return 'système';
      default:
        return entityType;
    }
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
