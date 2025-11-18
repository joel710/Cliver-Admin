import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../services/analytics_service.dart';

class SystemErrorsScreen extends StatefulWidget {
  const SystemErrorsScreen({super.key});

  @override
  State<SystemErrorsScreen> createState() => _SystemErrorsScreenState();
}

class _SystemErrorsScreenState extends State<SystemErrorsScreen> {
  List<Map<String, dynamic>> _errors = [];
  List<Map<String, dynamic>> _filteredErrors = [];
  bool _isLoading = true;
  String _selectedSeverity = 'all';
  String _selectedTimeRange = '7d';
  String _searchQuery = '';

  final List<String> _severityOptions = ['all', 'error', 'critical', 'warning'];
  final List<String> _timeRangeOptions = ['1d', '7d', '30d', 'all'];

  @override
  void initState() {
    super.initState();
    _loadErrors();
  }

  Future<void> _loadErrors() async {
    setState(() => _isLoading = true);
    
    try {
      final errors = await _fetchSystemErrors();
      if (mounted) {
        setState(() {
          _errors = errors;
          _filteredErrors = errors;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      debugPrint('Erreur chargement erreurs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSystemErrors() async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      
      switch (_selectedTimeRange) {
        case '1d':
          startDate = now.subtract(const Duration(days: 1));
          break;
        case '7d':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case '30d':
          startDate = now.subtract(const Duration(days: 30));
          break;
        default:
          startDate = DateTime(2020); // Très ancien pour récupérer tout
      }

      var query = AnalyticsService.supabase
          .from('audit_logs')
          .select('*')
          .gte('created_at', startDate.toIso8601String());

      if (_selectedSeverity != 'all') {
        query = query.eq('severity', _selectedSeverity);
      } else {
        query = query.inFilter('severity', ['error', 'critical', 'warning']);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(500);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur récupération erreurs: $e');
      return [];
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredErrors = _errors.where((error) {
        final matchesSearch = _searchQuery.isEmpty ||
            error['action']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
            error['details']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true;
        
        return matchesSearch;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  void _onSeverityChanged(String? severity) {
    if (severity != null) {
      setState(() => _selectedSeverity = severity);
      _loadErrors();
    }
  }

  void _onTimeRangeChanged(String? timeRange) {
    if (timeRange != null) {
      setState(() => _selectedTimeRange = timeRange);
      _loadErrors();
    }
  }

  Future<void> _clearError(String errorId) async {
    try {
      await AnalyticsService.supabase
          .from('audit_logs')
          .delete()
          .eq('id', errorId);
      
      await _loadErrors();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur supprimée', style: GoogleFonts.montserrat()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression', style: GoogleFonts.montserrat()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllErrors() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        content: Text('Voulez-vous vraiment supprimer toutes les erreurs ?', style: GoogleFonts.montserrat()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler', style: GoogleFonts.montserrat()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer tout', style: GoogleFonts.montserrat(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final errorIds = _filteredErrors.map((e) => e['id']).toList();
        await AnalyticsService.supabase
            .from('audit_logs')
            .delete()
            .inFilter('id', errorIds);
        
        await _loadErrors();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Toutes les erreurs ont été supprimées', style: GoogleFonts.montserrat()),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression', style: GoogleFonts.montserrat()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.arrow_left,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
        ),
        title: Text(
          'Erreurs Système',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          if (_filteredErrors.isNotEmpty)
            IconButton(
              onPressed: _clearAllErrors,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.trash,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Filtres et recherche
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Rechercher dans les erreurs...',
                    hintStyle: GoogleFonts.montserrat(color: colorScheme.outline),
                    prefixIcon: Icon(Iconsax.search_normal, color: colorScheme.outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Filtres
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSeverity,
                        decoration: InputDecoration(
                          labelText: 'Sévérité',
                          labelStyle: GoogleFonts.montserrat(),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _severityOptions.map((severity) => DropdownMenuItem(
                          value: severity,
                          child: Text(
                            severity == 'all' ? 'Toutes' : severity.toUpperCase(),
                            style: GoogleFonts.montserrat(),
                          ),
                        )).toList(),
                        onChanged: _onSeverityChanged,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTimeRange,
                        decoration: InputDecoration(
                          labelText: 'Période',
                          labelStyle: GoogleFonts.montserrat(),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _timeRangeOptions.map((range) => DropdownMenuItem(
                          value: range,
                          child: Text(
                            _getTimeRangeLabel(range),
                            style: GoogleFonts.montserrat(),
                          ),
                        )).toList(),
                        onChanged: _onTimeRangeChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Statistiques
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', _filteredErrors.length.toString(), Iconsax.danger, Colors.red),
                _buildStatItem('Critiques', _filteredErrors.where((e) => e['severity'] == 'critical').length.toString(), Iconsax.warning_2, Colors.red),
                _buildStatItem('Erreurs', _filteredErrors.where((e) => e['severity'] == 'error').length.toString(), Iconsax.info_circle, Colors.orange),
                _buildStatItem('Alertes', _filteredErrors.where((e) => e['severity'] == 'warning').length.toString(), Iconsax.notification, Colors.yellow),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Liste des erreurs
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  )
                : _filteredErrors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.tick_circle,
                              size: 64,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune erreur trouvée',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Le système fonctionne correctement',
                              style: GoogleFonts.montserrat(
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredErrors.length,
                        itemBuilder: (context, index) {
                          final error = _filteredErrors[index];
                          return _buildErrorCard(error);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(Map<String, dynamic> error) {
    final colorScheme = Theme.of(context).colorScheme;
    final severity = error['severity'] ?? 'error';
    final severityColor = _getSeverityColor(severity);
    final createdAt = DateTime.parse(error['created_at']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: severityColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: severityColor,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDateTime(createdAt),
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _clearError(error['id']),
                  icon: Icon(
                    Iconsax.trash,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              error['action'] ?? 'Action inconnue',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            
            if (error['details'] != null) ...[
              const SizedBox(height: 8),
              Text(
                error['details'],
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: colorScheme.outline,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            if (error['user_id'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Iconsax.user, size: 14, color: colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    'Utilisateur: ${error['user_id']}',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'error':
        return Colors.orange;
      case 'warning':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  String _getTimeRangeLabel(String range) {
    switch (range) {
      case '1d':
        return 'Dernières 24h';
      case '7d':
        return '7 derniers jours';
      case '30d':
        return '30 derniers jours';
      case 'all':
        return 'Toutes';
      default:
        return range;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
