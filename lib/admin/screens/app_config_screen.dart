import 'package:flutter/material.dart';
import '../services/app_config_service.dart';

class AppConfigScreen extends StatefulWidget {
  const AppConfigScreen({super.key});

  @override
  State<AppConfigScreen> createState() => _AppConfigScreenState();
}

class _AppConfigScreenState extends State<AppConfigScreen> {
  bool _isLoading = false;

  // Notifications
  final _notificationTitleController = TextEditingController();
  final _notificationMessageController = TextEditingController();
  final _notificationUrlController = TextEditingController();

  // Maintenance
  bool _maintenanceEnabled = false;
  final _maintenanceMessageController = TextEditingController();
  DateTime? _maintenanceEndDate;

  // Versions
  final _androidMinVersionController = TextEditingController();
  final _androidCurrentVersionController = TextEditingController();
  final _iosMinVersionController = TextEditingController();
  final _iosCurrentVersionController = TextEditingController();
  final _updateMessageController = TextEditingController();
  bool _forceAndroidUpdate = false;
  bool _forceIosUpdate = false;

  // Paramètres globaux
  final _waitTimeController = TextEditingController();
  final _searchRadiusController = TextEditingController();
  final _maxDriversController = TextEditingController();
  final _baseFareController = TextEditingController();
  final _farePerKmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    setState(() => _isLoading = true);

    try {
      // Charger maintenance
      final maintenance = await AppConfigService.getMaintenanceStatus();
      if (maintenance != null) {
        _maintenanceEnabled = maintenance['enabled'] ?? false;
        _maintenanceMessageController.text = maintenance['message'] ?? '';
        if (maintenance['scheduled_end'] != null) {
          _maintenanceEndDate = DateTime.parse(maintenance['scheduled_end']);
        }
      }

      // Charger versions
      final androidVersion = await AppConfigService.getAppVersion('android');
      if (androidVersion != null) {
        _androidMinVersionController.text = androidVersion['min_version'] ?? '';
        _androidCurrentVersionController.text =
            androidVersion['current_version'] ?? '';
        _forceAndroidUpdate = androidVersion['force_update'] ?? false;
      }

      final iosVersion = await AppConfigService.getAppVersion('ios');
      if (iosVersion != null) {
        _iosMinVersionController.text = iosVersion['min_version'] ?? '';
        _iosCurrentVersionController.text = iosVersion['current_version'] ?? '';
        _forceIosUpdate = iosVersion['force_update'] ?? false;
      }

      // Charger paramètres globaux
      final globalSettings = await AppConfigService.getGlobalSettings();
      if (globalSettings != null) {
        _waitTimeController.text =
            globalSettings['wait_time_seconds']?.toString() ?? '';
        _searchRadiusController.text =
            globalSettings['search_radius_km']?.toString() ?? '';
        _maxDriversController.text =
            globalSettings['max_drivers_per_request']?.toString() ?? '';
        _baseFareController.text =
            globalSettings['base_fare']?.toString() ?? '';
        _farePerKmController.text =
            globalSettings['fare_per_km']?.toString() ?? '';
      }
    } catch (e) {
      _showSnackBar('Erreur lors du chargement: $e', isError: true);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration de l\'app'),
        backgroundColor: Colors.orange,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildNotificationsSection(),
                  const SizedBox(height: 24),
                  _buildMaintenanceSection(),
                  const SizedBox(height: 24),
                  _buildVersionsSection(),
                  const SizedBox(height: 24),
                  _buildGlobalSettingsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Notifications Push',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notificationTitleController,
              decoration: const InputDecoration(
                labelText: 'Titre de la notification',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notificationMessageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notificationUrlController,
              decoration: const InputDecoration(
                labelText: 'URL d\'action (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sendNotificationToAll,
                icon: const Icon(Icons.send),
                label: const Text('Envoyer à tous les utilisateurs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Mode Maintenance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Activer le mode maintenance'),
              value: _maintenanceEnabled,
              onChanged: (value) => setState(() => _maintenanceEnabled = value),
              activeColor: Colors.orange,
            ),
            if (_maintenanceEnabled) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _maintenanceMessageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message de maintenance',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Fin prévue'),
                subtitle: Text(
                  _maintenanceEndDate?.toString() ?? 'Non définie',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectMaintenanceEndDate,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _updateMaintenanceMode,
                icon: const Icon(Icons.save),
                label: const Text('Sauvegarder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.system_update, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Versions de l\'app',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Android', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _androidMinVersionController,
                    decoration: const InputDecoration(
                      labelText: 'Version minimale',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _androidCurrentVersionController,
                    decoration: const InputDecoration(
                      labelText: 'Version actuelle',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            CheckboxListTile(
              title: const Text('Forcer la mise à jour Android'),
              value: _forceAndroidUpdate,
              onChanged: (value) =>
                  setState(() => _forceAndroidUpdate = value ?? false),
              activeColor: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text('iOS', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _iosMinVersionController,
                    decoration: const InputDecoration(
                      labelText: 'Version minimale',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _iosCurrentVersionController,
                    decoration: const InputDecoration(
                      labelText: 'Version actuelle',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            CheckboxListTile(
              title: const Text('Forcer la mise à jour iOS'),
              value: _forceIosUpdate,
              onChanged: (value) =>
                  setState(() => _forceIosUpdate = value ?? false),
              activeColor: Colors.orange,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _updateMessageController,
              decoration: const InputDecoration(
                labelText: 'Message de mise à jour',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _updateAppVersions,
                icon: const Icon(Icons.save),
                label: const Text('Sauvegarder les versions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Paramètres Globaux',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _waitTimeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Temps d\'attente (sec)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchRadiusController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Rayon de recherche (km)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxDriversController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nombre max de chauffeurs par requête',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _baseFareController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tarif de base (Fcfa)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _farePerKmController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tarif par km (Fcfa)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _updateGlobalSettings,
                icon: const Icon(Icons.save),
                label: const Text('Sauvegarder les paramètres'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendNotificationToAll() async {
    if (_notificationTitleController.text.isEmpty ||
        _notificationMessageController.text.isEmpty) {
      _showSnackBar('Veuillez remplir le titre et le message', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await AppConfigService.sendPushNotificationToAll(
      title: _notificationTitleController.text,
      message: _notificationMessageController.text,
      actionUrl: _notificationUrlController.text.isEmpty
          ? null
          : _notificationUrlController.text,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final sentCount = result['sent_count'] ?? 0;
      final failedCount = result['failed_count'] ?? 0;

      _showSnackBar(
        'Notification envoyée: $sentCount succès, $failedCount échecs',
        isError: failedCount > sentCount,
      );

      _notificationTitleController.clear();
      _notificationMessageController.clear();
      _notificationUrlController.clear();
    } else {
      final details = result['details'] ?? {};
      final error = details['error'] ?? 'Erreur inconnue';
      final errorType = details['type'] ?? '';
      final stackTrace = details['stack_trace'] ?? '';

      print('🔍 Détails de l\'erreur:');
      print('   Error: $error');
      print('   Type: $errorType');
      print('   Stack: $stackTrace');

      String displayError = error;
      if (errorType.isNotEmpty) {
        displayError = '$errorType: $error';
      }

      _showSnackBar('Erreur lors de l\'envoi: $displayError', isError: true);
    }
  }

  Future<void> _updateMaintenanceMode() async {
    setState(() => _isLoading = true);

    final success = await AppConfigService.setMaintenanceMode(
      enabled: _maintenanceEnabled,
      message: _maintenanceMessageController.text,
      scheduledEnd: _maintenanceEndDate,
    );

    setState(() => _isLoading = false);

    if (success) {
      _showSnackBar('Mode maintenance mis à jour');
    } else {
      _showSnackBar('Erreur lors de la mise à jour', isError: true);
    }
  }

  Future<void> _updateAppVersions() async {
    setState(() => _isLoading = true);

    bool androidSuccess = true;
    bool iosSuccess = true;

    if (_androidMinVersionController.text.isNotEmpty &&
        _androidCurrentVersionController.text.isNotEmpty) {
      androidSuccess = await AppConfigService.setAppVersion(
        platform: 'android',
        minVersion: _androidMinVersionController.text,
        currentVersion: _androidCurrentVersionController.text,
        forceUpdate: _forceAndroidUpdate,
        updateMessage: _updateMessageController.text,
      );
    }

    if (_iosMinVersionController.text.isNotEmpty &&
        _iosCurrentVersionController.text.isNotEmpty) {
      iosSuccess = await AppConfigService.setAppVersion(
        platform: 'ios',
        minVersion: _iosMinVersionController.text,
        currentVersion: _iosCurrentVersionController.text,
        forceUpdate: _forceIosUpdate,
        updateMessage: _updateMessageController.text,
      );
    }

    setState(() => _isLoading = false);

    if (androidSuccess && iosSuccess) {
      _showSnackBar('Versions mises à jour avec succès');
    } else {
      _showSnackBar(
        'Erreur lors de la mise à jour des versions',
        isError: true,
      );
    }
  }

  Future<void> _updateGlobalSettings() async {
    setState(() => _isLoading = true);

    final success = await AppConfigService.setGlobalSettings(
      waitTimeSeconds: int.tryParse(_waitTimeController.text),
      searchRadiusKm: double.tryParse(_searchRadiusController.text),
      maxDriversPerRequest: int.tryParse(_maxDriversController.text),
      baseFare: double.tryParse(_baseFareController.text),
      farePerKm: double.tryParse(_farePerKmController.text),
    );

    setState(() => _isLoading = false);

    if (success) {
      _showSnackBar('Paramètres globaux mis à jour');
    } else {
      _showSnackBar('Erreur lors de la mise à jour', isError: true);
    }
  }

  Future<void> _selectMaintenanceEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _maintenanceEndDate ?? DateTime.now().add(const Duration(hours: 2)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _maintenanceEndDate ?? DateTime.now(),
        ),
      );

      if (time != null) {
        setState(() {
          _maintenanceEndDate = DateTime(
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

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _notificationTitleController.dispose();
    _notificationMessageController.dispose();
    _notificationUrlController.dispose();
    _maintenanceMessageController.dispose();
    _androidMinVersionController.dispose();
    _androidCurrentVersionController.dispose();
    _iosMinVersionController.dispose();
    _iosCurrentVersionController.dispose();
    _updateMessageController.dispose();
    _waitTimeController.dispose();
    _searchRadiusController.dispose();
    _maxDriversController.dispose();
    _baseFareController.dispose();
    _farePerKmController.dispose();
    super.dispose();
  }
}
