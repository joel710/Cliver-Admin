import 'package:flutter/material.dart';

class KycStatusChip extends StatelessWidget {
  final String status; // pending | approved | rejected | correction_requested
  const KycStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'approved':
        color = Colors.green.shade700;
        break;
      case 'rejected':
        color = Colors.red.shade700;
        break;
      case 'correction_requested':
        color = Colors.orange.shade700;
        break;
      default:
        color = Colors.grey.shade700;
    }
    return Chip(
      label: Text(status),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color),
      side: BorderSide(color: color),
    );
  }
}
