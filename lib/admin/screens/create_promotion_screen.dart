import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../services/promotions_service.dart';
import '../widgets/user_selector_dialog.dart';

class CreatePromotionScreen extends StatefulWidget {
  const CreatePromotionScreen({super.key});

  @override
  State<CreatePromotionScreen> createState() => _CreatePromotionScreenState();
}

class _CreatePromotionScreenState extends State<CreatePromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountPercentageController = TextEditingController();
  final _discountAmountController = TextEditingController();
  final _minSubscriptionPriceController = TextEditingController();
  final _maxUsesController = TextEditingController();

  String _promotionType = 'percentage';
  String _targetType = 'all_users';
  String? _targetRole;
  String? _selectedPlanId;
  DateTime? _expiresAt;
  final List<Map<String, dynamic>> _selectedUsers = [];
  List<Map<String, dynamic>> _subscriptionPlans = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionPlans();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _discountPercentageController.dispose();
    _discountAmountController.dispose();
    _minSubscriptionPriceController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptionPlans() async {
    try {
      final plans = await PromotionsService.getSubscriptionPlans();
      setState(() {
        _subscriptionPlans = plans;
      });
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des plans: $e');
    }
  }

  Future<void> _createPromotion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await PromotionsService.createPromotion(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        promotionType: _promotionType,
        discountPercentage: _promotionType == 'percentage' 
            ? double.tryParse(_discountPercentageController.text)
            : null,
        discountAmount: _promotionType == 'fixed_amount'
            ? double.tryParse(_discountAmountController.text)
            : null,
        freeSubscriptionPlanId: _promotionType == 'free_subscription'
            ? _selectedPlanId
            : null,
        targetType: _targetType,
        targetRole: _targetRole,
        targetUserIds: _selectedUsers.map((u) => u['id'] as String).toList(),
        minSubscriptionPrice: _minSubscriptionPriceController.text.isNotEmpty
            ? double.tryParse(_minSubscriptionPriceController.text)
            : null,
        expiresAt: _expiresAt,
        maxUses: _maxUsesController.text.isNotEmpty
            ? int.tryParse(_maxUsesController.text)
            : null,
      );

      if (mounted) {
        Navigator.pop(context, true);
        _showSuccessSnackBar('Promotion créée avec succès!');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la création: $e');
    } finally {
      setState(() => _isLoading = false);
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Créer une Promotion',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations de base
              _buildSectionCard(
                title: 'Informations de base',
                icon: Iconsax.info_circle,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nom de la promotion',
                    hint: 'Ex: Réduction Nouvel An',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le nom est requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Décrivez cette promotion...',
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Type de promotion
              _buildSectionCard(
                title: 'Type de promotion',
                icon: Iconsax.percentage_circle,
                children: [
                  _buildPromotionTypeSelector(),
                  const SizedBox(height: 16),
                  _buildPromotionValueInput(),
                ],
              ),

              const SizedBox(height: 16),

              // Ciblage
              _buildSectionCard(
                title: 'Ciblage',
                icon: Iconsax.people,
                children: [
                  _buildTargetTypeSelector(),
                  const SizedBox(height: 16),
                  _buildTargetSpecificInput(),
                ],
              ),

              const SizedBox(height: 16),

              // Conditions et limites
              _buildSectionCard(
                title: 'Conditions et limites',
                icon: Iconsax.setting_2,
                children: [
                  _buildTextField(
                    controller: _minSubscriptionPriceController,
                    label: 'Prix minimum d\'abonnement (XOF)',
                    hint: 'Ex: 5000',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _maxUsesController,
                    label: 'Nombre maximum d\'utilisations',
                    hint: 'Laissez vide pour illimité',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildDatePicker(),
                ],
              ),

              const SizedBox(height: 24),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Annuler',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createPromotion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              'Créer la promotion',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildPromotionTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de réduction',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPromotionTypeOption(
                'percentage',
                'Pourcentage',
                Iconsax.percentage_circle,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPromotionTypeOption(
                'fixed_amount',
                'Montant fixe',
                Iconsax.money,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPromotionTypeOption(
                'free_subscription',
                'Abonnement gratuit',
                Iconsax.gift,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromotionTypeOption(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _promotionType == value;
    
    return GestureDetector(
      onTap: () => setState(() => _promotionType = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionValueInput() {
    switch (_promotionType) {
      case 'percentage':
        return _buildTextField(
          controller: _discountPercentageController,
          label: 'Pourcentage de réduction (%)',
          hint: 'Ex: 20',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le pourcentage est requis';
            }
            final percentage = double.tryParse(value);
            if (percentage == null || percentage <= 0 || percentage > 100) {
              return 'Entrez un pourcentage valide (1-100)';
            }
            return null;
          },
        );
      
      case 'fixed_amount':
        return _buildTextField(
          controller: _discountAmountController,
          label: 'Montant de réduction (XOF)',
          hint: 'Ex: 1000',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le montant est requis';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Entrez un montant valide';
            }
            return null;
          },
        );
      
      case 'free_subscription':
        return DropdownButtonFormField<String>(
          value: _selectedPlanId,
          decoration: InputDecoration(
            labelText: 'Plan d\'abonnement gratuit',
            labelStyle: GoogleFonts.poppins(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          items: _subscriptionPlans.map((plan) {
            return DropdownMenuItem<String>(
              value: plan['id'],
              child: Text(
                '${plan['name']} - ${plan['price']} XOF',
                style: GoogleFonts.poppins(),
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedPlanId = value),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Sélectionnez un plan d\'abonnement';
            }
            return null;
          },
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTargetTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Qui peut utiliser cette promotion ?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _targetType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          items: const [
            DropdownMenuItem(value: 'all_users', child: Text('Tous les utilisateurs')),
            DropdownMenuItem(value: 'specific_users', child: Text('Utilisateurs spécifiques')),
            DropdownMenuItem(value: 'user_role', child: Text('Par rôle d\'utilisateur')),
            DropdownMenuItem(value: 'new_users', child: Text('Nouveaux utilisateurs (30 jours)')),
          ],
          onChanged: (value) => setState(() {
            _targetType = value!;
            _targetRole = null;
            _selectedUsers.clear();
          }),
        ),
      ],
    );
  }

  Widget _buildTargetSpecificInput() {
    switch (_targetType) {
      case 'user_role':
        return DropdownButtonFormField<String>(
          value: _targetRole,
          decoration: InputDecoration(
            labelText: 'Rôle d\'utilisateur',
            labelStyle: GoogleFonts.poppins(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          items: const [
            DropdownMenuItem(value: 'client', child: Text('Clients')),
            DropdownMenuItem(value: 'livreur', child: Text('Livreurs')),
          ],
          onChanged: (value) => setState(() => _targetRole = value),
          validator: (value) {
            if (_targetType == 'user_role' && (value == null || value.isEmpty)) {
              return 'Sélectionnez un rôle';
            }
            return null;
          },
        );
      
      case 'specific_users':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _showUserSelectionDialog,
              icon: const Icon(Iconsax.add),
              label: Text(
                'Sélectionner des utilisateurs',
                style: GoogleFonts.poppins(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                elevation: 0,
              ),
            ),
            if (_selectedUsers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedUsers.map((user) {
                  return Chip(
                    label: Text(
                      user['fullname'] ?? user['email'] ?? 'Utilisateur',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    onDeleted: () {
                      setState(() {
                        _selectedUsers.remove(user);
                      });
                    },
                    deleteIcon: const Icon(Iconsax.close_circle, size: 16),
                  );
                }).toList(),
              ),
            ],
          ],
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date d\'expiration (optionnel)',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectExpirationDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.calendar,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _expiresAt != null
                        ? 'Expire le ${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year} à ${_expiresAt!.hour}:${_expiresAt!.minute.toString().padLeft(2, '0')}'
                        : 'Sélectionner une date d\'expiration',
                    style: GoogleFonts.poppins(
                      color: _expiresAt != null
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_expiresAt != null)
                  IconButton(
                    onPressed: () => setState(() => _expiresAt = null),
                    icon: const Icon(Iconsax.close_circle),
                    iconSize: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectExpirationDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _expiresAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _showUserSelectionDialog() async {
    showDialog(
      context: context,
      builder: (context) => UserSelectorDialog(
        onUserSelected: (user) {
          setState(() {
            // Vérifier si l'utilisateur n'est pas déjà sélectionné
            final isAlreadySelected = _selectedUsers.any((u) => u['id'] == user['id']);
            if (!isAlreadySelected) {
              _selectedUsers.add(user);
            }
          });
        },
      ),
    );
  }
}
