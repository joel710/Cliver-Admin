import 'package:flutter/material.dart';
import '../services/maintenance_service.dart';
import '../screens/maintenance_screen.dart';

class MaintenanceWrapper extends StatefulWidget {
  final Widget child;

  const MaintenanceWrapper({
    super.key,
    required this.child,
  });

  @override
  State<MaintenanceWrapper> createState() => _MaintenanceWrapperState();
}

class _MaintenanceWrapperState extends State<MaintenanceWrapper> {
  MaintenanceStatus? _maintenanceStatus;
  bool _isLoading = true;
  bool _canBypass = false;

  @override
  void initState() {
    super.initState();
    _checkMaintenanceStatus();
  }

  Future<void> _checkMaintenanceStatus() async {
    try {
      final status = await MaintenanceService.checkMaintenanceStatus();
      final canBypass = await MaintenanceService.canBypassMaintenance();
      
      if (mounted) {
        setState(() {
          _maintenanceStatus = status;
          _canBypass = canBypass;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur vérification maintenance: $e');
      if (mounted) {
        setState(() {
          _maintenanceStatus = MaintenanceStatus(enabled: false);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si maintenance active et utilisateur ne peut pas bypasser
    if (_maintenanceStatus != null && 
        _maintenanceStatus!.isActive && 
        !_canBypass) {
      return MaintenanceScreen(maintenanceStatus: _maintenanceStatus!);
    }

    // Sinon, afficher l'app normale
    return widget.child;
  }
}
