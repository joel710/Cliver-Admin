import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuickActionsScreen extends StatelessWidget {
  const QuickActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.people,
        label: 'Clients',
        onTap: () => context.push('/clients-monitor'),
      ),
      _QuickAction(
        icon: Icons.local_shipping,
        label: 'Livreurs',
        onTap: () => context.push('/drivers-monitor'),
      ),
      _QuickAction(
        icon: Icons.map,
        label: 'Carte',
        onTap: () => context.push('/map-tracking'),
      ),
      _QuickAction(
        icon: Icons.support_agent,
        label: 'Support',
        onTap: () => context.push('/support'),
      ),
      _QuickAction(
        icon: Icons.flag,
        label: 'Reports',
        onTap: () => context.push('/reports'),
      ),
      _QuickAction(
        icon: Icons.verified_user,
        label: 'KYC',
        onTap: () => context.push('/'), // goes to main then tab KYC; can refine later
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Actions rapides')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: actions
              .map((a) => _ActionCard(icon: a.icon, label: a.label, onTap: a.onTap))
              .toList(),
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _QuickAction({required this.icon, required this.label, required this.onTap});
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
