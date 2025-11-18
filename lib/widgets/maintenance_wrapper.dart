import 'package:flutter/material.dart';
import '../services/maintenance_service.dart';
import '../screens/maintenance_screen.dart';

class MaintenanceWrapper extends StatefulWidget {
  final Widget child;

  const MaintenanceWrapper({super.key, required this.child});

  @override
  State<MaintenanceWrapper> createState() => _MaintenanceWrapperState();
}

class _MaintenanceWrapperState extends State<MaintenanceWrapper> {
  MaintenanceStatus? _maintenanceStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkMaintenanceStatus();
  }

  Future<void> _checkMaintenanceStatus() async {
    try {
      final status = await MaintenanceService.checkMaintenanceStatus();

      if (mounted) {
        setState(() {
          _maintenanceStatus = status;
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
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFFFF7A00)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Vérification du statut...',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Si maintenance active, afficher l'écran de maintenance
    if (_maintenanceStatus != null && _maintenanceStatus!.isActive) {
      return MaintenanceScreen(maintenanceStatus: _maintenanceStatus!);
    }

    // Sinon, afficher l'app normale
    return widget.child;
  }
}
