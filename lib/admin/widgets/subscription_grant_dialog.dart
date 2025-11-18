import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../services/subscription_grants_service.dart';
import 'user_selector_dialog.dart';

class SubscriptionGrantDialog extends StatefulWidget {
  final Function() onGrantCreated;

  const SubscriptionGrantDialog({
    super.key,
    required this.onGrantCreated,
  });

  @override
  State<SubscriptionGrantDialog> createState() => _SubscriptionGrantDialogState();
}

class _SubscriptionGrantDialogState extends State<SubscriptionGrantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  Map<String, dynamic>? _selectedUser;
  String? _selectedPlanId;
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = false;
  bool _isLoadingPlans = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void dispose() {
    _durationController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await SubscriptionGrantsService.getSubscriptionPlans();
      if (mounted) {
        setState(() {
          _plans = plans;
          _isLoadingPlans = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPlans = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des plans: $e')),
        );
      }
    }
  }

  Future<void> _grantSubscription() async {
    if (!_formKey.currentState!.validate() || _selectedUser == null || _selectedPlanId == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await SubscriptionGrantsService.grantSubscriptionToUser(
        userId: _selectedUser!['id'],
        planId: _selectedPlanId!,
        durationDays: int.parse(_durationController.text),
        reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
        adminNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abonnement attribué avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onGrantCreated();
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

  void _selectUser() {
    showDialog(
      context: context,
      builder: (context) => UserSelectorDialog(
        onUserSelected: (user) {
          setState(() => _selectedUser = user);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Iconsax.crown,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Attribuer un Abonnement',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Iconsax.close_circle),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // User Selection
              Text(
                'Utilisateur *',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              
              InkWell(
                onTap: _selectUser,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedUser == null
                      ? Row(
                          children: [
                            Icon(
                              Iconsax.user_add,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Sélectionner un utilisateur',
                              style: GoogleFonts.montserrat(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        )
                      : Row(
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
                                    _selectedUser!['fullname'] ?? 'Nom non défini',
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (_selectedUser!['email'] != null)
                                    Text(
                                      _selectedUser!['email'],
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
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _selectedUser!['role']?.toUpperCase() ?? 'N/A',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Plan Selection
              Text(
                'Plan d\'abonnement *',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              
              DropdownButtonFormField<String>(
                value: _selectedPlanId,
                decoration: InputDecoration(
                  hintText: 'Sélectionner un plan',
                  hintStyle: GoogleFonts.montserrat(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Iconsax.crown),
                ),
                validator: (value) => value == null ? 'Veuillez sélectionner un plan' : null,
                items: _isLoadingPlans
                    ? [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Chargement...', style: GoogleFonts.montserrat()),
                        )
                      ]
                    : _plans.map((plan) {
                        return DropdownMenuItem<String>(
                          value: plan['id'],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                plan['name'] ?? 'Plan sans nom',
                                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                              ),
                              if (plan['price'] != null)
                                Text(
                                  '${plan['price']} FCFA',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                onChanged: (value) => setState(() => _selectedPlanId = value),
              ),

              const SizedBox(height: 20),

              // Duration
              Text(
                'Durée (en jours) *',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ex: 30',
                  hintStyle: GoogleFonts.montserrat(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Iconsax.calendar),
                  suffixText: 'jours',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une durée';
                  }
                  final duration = int.tryParse(value);
                  if (duration == null || duration <= 0) {
                    return 'Veuillez entrer une durée valide';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Reason
              Text(
                'Raison (optionnel)',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  hintText: 'Ex: Promotion spéciale, compensation...',
                  hintStyle: GoogleFonts.montserrat(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Iconsax.message_text),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 20),

              // Admin Notes
              Text(
                'Notes administratives (optionnel)',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'Notes internes pour les administrateurs...',
                  hintStyle: GoogleFonts.montserrat(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Iconsax.note),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Annuler',
                      style: GoogleFonts.montserrat(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _grantSubscription,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Iconsax.crown),
                    label: Text(
                      _isLoading ? 'Attribution...' : 'Attribuer',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
