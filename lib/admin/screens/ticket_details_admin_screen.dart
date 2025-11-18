import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../services/support_service.dart';
import '../services/support_realtime_service.dart';

class TicketDetailsAdminScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;

  const TicketDetailsAdminScreen({
    super.key,
    required this.ticket,
  });

  @override
  State<TicketDetailsAdminScreen> createState() => _TicketDetailsAdminScreenState();
}

class _TicketDetailsAdminScreenState extends State<TicketDetailsAdminScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.ticket['statut'] ?? 'open';
    _loadComments();
    _startRealtimeListening();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    SupportRealtimeService.stopListening(widget.ticket['id']);
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await SupportService.getTicketComments(widget.ticket['id']);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Erreur lors du chargement des commentaires: $e');
      }
    }
  }

  void _startRealtimeListening() {
    print('🔥 [ADMIN UI] Démarrage écoute real-time pour ticket: ${widget.ticket['id']}');
    
    SupportRealtimeService.startListening(
      widget.ticket['id'],
      (comments) {
        if (mounted) {
          print('🔥 [ADMIN UI] Mise à jour reçue: ${comments.length} commentaires');
          
          setState(() {
            _comments = comments;
          });
          
          // Défilement automatique vers le bas
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      },
    );
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;

    // Vérifier si le ticket est fermé
    if (_currentStatus == 'closed') {
      _showError('Impossible d\'ajouter un commentaire sur un ticket fermé');
      return;
    }

    setState(() => _isSending = true);

    try {
      await SupportService.addTicketComment(
        widget.ticket['id'],
        _commentController.text.trim(),
      );

      _commentController.clear();
      
      if (mounted) {
        setState(() => _isSending = false);
        // Pas besoin de recharger, le real-time va mettre à jour automatiquement
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        _showError('Erreur lors de l\'envoi: $e');
      }
    }
  }

  Future<void> _updateTicketStatus(String newStatus) async {
    try {
      await SupportService.updateTicketStatus(widget.ticket['id'], newStatus);
      
      if (mounted) {
        setState(() => _currentStatus = newStatus);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Statut mis à jour: ${_getStatusText(newStatus)}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: _getStatusColor(newStatus),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      _showError('Erreur lors de la mise à jour: $e');
    }
  }

  void _updateStatus(String newStatus) {
    if (newStatus == 'closed') {
      _showCloseConfirmation();
    } else {
      _updateTicketStatus(newStatus);
    }
  }

  void _showCloseConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Fermer le ticket',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir fermer définitivement ce ticket ? Cette action :\n\n'
          '• Marque le problème comme résolu définitivement\n'
          '• Empêche de nouveaux commentaires\n'
          '• Archive la conversation\n'
          '• Ne peut pas être annulée',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _closeTicket();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Fermer définitivement',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _closeTicket() async {
    try {
      await SupportService.closeTicket(widget.ticket['id']);
      
      if (mounted) {
        setState(() => _currentStatus = 'closed');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Iconsax.lock, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Ticket fermé définitivement',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      _showError('Erreur lors de la fermeture: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Iconsax.warning_2, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message, style: GoogleFonts.poppins())),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.red;
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'open':
        return Iconsax.clock;
      case 'in_progress':
        return Iconsax.refresh;
      case 'resolved':
        return Iconsax.tick_circle;
      case 'closed':
        return Iconsax.lock;
      default:
        return Iconsax.info_circle;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'urgent':
        return Iconsax.danger;
      case 'high':
        return Iconsax.warning_2;
      case 'medium':
        return Iconsax.info_circle;
      case 'low':
        return Iconsax.tick_circle;
      default:
        return Iconsax.info_circle;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'urgent':
        return 'Urgent';
      case 'high':
        return 'Élevée';
      case 'medium':
        return 'Moyenne';
      case 'low':
        return 'Faible';
      default:
        return 'Inconnue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        elevation: 0,
        title: Text(
          'Ticket #${widget.ticket['id'].toString().substring(0, 8)}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Iconsax.more, color: Theme.of(context).colorScheme.primary),
            ),
            onSelected: (value) => _updateStatus(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'open',
                child: Text('Ouvrir'),
              ),
              const PopupMenuItem(
                value: 'in_progress',
                child: Text('En cours'),
              ),
              const PopupMenuItem(
                value: 'resolved',
                child: Text('Résolu'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'closed',
                child: Row(
                  children: [
                    Icon(Iconsax.lock, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Fermer définitivement', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // En-tête du ticket
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et badges
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.ticket['probleme'] ?? 'Sans titre',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Badge priorité
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(widget.ticket['priorite'] ?? 'medium').withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getPriorityText(widget.ticket['priorite'] ?? 'medium'),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getPriorityColor(widget.ticket['priorite'] ?? 'medium'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Utilisateur et statut
                Row(
                  children: [
                    Icon(Iconsax.user, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      widget.ticket['user_nom'] ?? 'Utilisateur inconnu',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getRoleColor(widget.ticket['user_role']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getRoleText(widget.ticket['user_role']),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getRoleColor(widget.ticket['user_role']),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_currentStatus).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(_currentStatus),
                            size: 12,
                            color: _getStatusColor(_currentStatus),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusText(_currentStatus),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(_currentStatus),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Date de création
                Row(
                  children: [
                    Icon(Iconsax.calendar, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'Créé le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(widget.ticket['date_creation']))}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          
          // Zone de discussion
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // En-tête discussion
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLowest,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Iconsax.messages, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Discussion avec l\'utilisateur',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_comments.length} commentaire${_comments.length > 1 ? 's' : ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Liste des commentaires
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : _comments.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Iconsax.message,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aucun message pour le moment',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Commencez la discussion avec l\'utilisateur',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: _comments.length,
                                itemBuilder: (context, index) {
                                  final comment = _comments[index];
                                  final isAdmin = comment['sender_type'] == 'admin';
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Avatar
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isAdmin ? Colors.blue : Colors.orange,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isAdmin ? Iconsax.user_octagon : Iconsax.user,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        
                                        // Bulle de message
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // En-tête du message
                                              Row(
                                                children: [
                                                  Text(
                                                    comment['sender_name'] ?? (isAdmin ? 'Support Admin' : 'Utilisateur'),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: isAdmin ? Colors.blue : Colors.orange,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    DateFormat('dd/MM à HH:mm').format(
                                                      DateTime.parse(comment['date_creation']),
                                                    ),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              
                                              // Contenu du message
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: isAdmin 
                                                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  comment['message'] ?? '',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    color: Theme.of(context).colorScheme.onSurface,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
          
          // Zone de saisie
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _commentController,
                      maxLines: null,
                      enabled: _currentStatus != 'closed',
                      decoration: InputDecoration(
                        hintText: _currentStatus == 'closed' 
                            ? 'Ticket fermé - Commentaires désactivés'
                            : 'Tapez votre réponse...',
                        hintStyle: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Bouton d'envoi
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: (_isSending || _currentStatus == 'closed') ? null : _sendComment,
                    icon: _isSending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : Icon(
                            Iconsax.send_1,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'client':
        return Colors.blue;
      case 'livreur':
        return Colors.orange;
      case 'entreprise':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getRoleText(String? role) {
    switch (role?.toLowerCase()) {
      case 'client':
        return 'CLIENT';
      case 'livreur':
        return 'LIVREUR';
      case 'entreprise':
        return 'ENTREPRISE';
      default:
        return 'UTILISATEUR';
    }
  }
}
