import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../services/support_service.dart';
import 'ticket_details_admin_screen.dart';
import 'select_user_screen.dart';

class SupportDashboardScreen extends StatefulWidget {
  const SupportDashboardScreen({super.key});

  @override
  State<SupportDashboardScreen> createState() => _SupportDashboardScreenState();
}

class _SupportDashboardScreenState extends State<SupportDashboardScreen> {
  List<Map<String, dynamic>> supportTickets = [];
  Map<String, dynamic> ticketsStats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSupportTickets();
  }

  Future<void> _loadSupportTickets() async {
    try {
      setState(() => isLoading = true);
      final stats = await SupportService.getTicketsStats();
      final tickets = await SupportService.getAllTickets();
      if (!mounted) return;
      setState(() {
        ticketsStats = stats;
        supportTickets = tickets;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support & Incidents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSupportTickets,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // En-tête avec statistiques
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SupportStatCard(
                          title: 'Tickets ouverts',
                          value: '${ticketsStats['open'] ?? 0}',
                          color: Colors.red,
                          icon: Icons.support_agent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SupportStatCard(
                          title: 'En cours',
                          value: '${ticketsStats['in_progress'] ?? 0}',
                          color: Colors.orange,
                          icon: Icons.pending,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SupportStatCard(
                          title: 'Résolus',
                          value: '${ticketsStats['resolved'] ?? 0}',
                          color: Colors.green,
                          icon: Icons.check_circle,
                        ),
                      ),
                    ],
                  ),
                ),

                // Filtres rapides
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Tous',
                        isSelected: true,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Urgent',
                        isSelected: false,
                        onTap: () {},
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Technique',
                        isSelected: false,
                        onTap: () {},
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Liste des tickets de support
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: supportTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = supportTickets[index];
                      return _SupportTicketCard(
                        ticket: ticket,
                        onTap: () => _showTicketDetails(context, ticket),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateTicket(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Iconsax.add),
        label: Text(
          'Nouveau ticket',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showTicketDetails(BuildContext context, Map<String, dynamic> ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailsAdminScreen(ticket: ticket),
      ),
    ).then((_) {
      // Recharger les tickets après retour de l'écran de détails
      _loadSupportTickets();
    });
  }

  void _navigateToCreateTicket() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectUserScreen(),
      ),
    ).then((result) {
      if (result == true) {
        // Ticket créé avec succès, recharger la liste
        _loadSupportTickets();
      }
    });
  }
}

class _SupportStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SupportStatCard({
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

class _SupportTicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final VoidCallback onTap;

  const _SupportTicketCard({
    required this.ticket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = ticket['statut'] ?? 'open';
    final priority = ticket['priorite'] ?? 'medium';
    final userName = ticket['user_nom'] ?? 'Utilisateur';
    final userRole = ticket['user_role'] ?? 'client';
    final problem = ticket['probleme'] ?? 'Aucune description';
    final dateCreation = ticket['date_creation'] != null 
        ? DateTime.parse(ticket['date_creation'])
        : DateTime.now();

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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec statut et priorité
                Row(
                  children: [
                    // ID du ticket
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${ticket['id'].toString().substring(0, 8)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Priorité
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.flag,
                            size: 12,
                            color: _getPriorityColor(priority),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getPriorityText(priority),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _getPriorityColor(priority),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Statut
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(status),
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
                
                // Utilisateur
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getRoleColor(userRole).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getRoleIcon(userRole),
                        size: 16,
                        color: _getRoleColor(userRole),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            _getRoleText(userRole),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM à HH:mm').format(dateCreation),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Description du problème
                Text(
                  problem,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'Ouvert';
      case 'in_progress':
        return 'En cours';
      case 'resolved':
        return 'Résolu';
      case 'closed':
        return 'Fermé';
      default:
        return 'Inconnu';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'high':
        return 'Haute';
      case 'medium':
        return 'Moyenne';
      case 'low':
        return 'Basse';
      default:
        return 'Inconnue';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'livreur':
        return Colors.blue;
      case 'business':
        return Colors.purple;
      case 'admin':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'livreur':
        return Iconsax.user_octagon;
      case 'business':
        return Iconsax.building;
      case 'admin':
        return Iconsax.shield_tick;
      default:
        return Iconsax.user;
    }
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'livreur':
        return 'Livreur';
      case 'business':
        return 'Entreprise';
      case 'admin':
        return 'Administrateur';
      default:
        return 'Client';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color ?? Theme.of(context).primaryColor,
      checkmarkColor: Colors.white,
    );
  }
}