import 'package:flutter/material.dart';

class DecisionDialog extends StatefulWidget {
  final String type; // approve | reject | correction
  const DecisionDialog({super.key, required this.type});
  @override
  State<DecisionDialog> createState() => _DecisionDialogState();
}

class _DecisionDialogState extends State<DecisionDialog> {
  final ctrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final needReason = widget.type != 'approve';
    return AlertDialog(
      title: Text(widget.type == 'reject' ? 'Refuser (motif)' : widget.type == 'correction' ? 'Demander correction (motif)' : 'Approuver'),
      content: needReason
          ? TextField(controller: ctrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Veuillez saisir le motif'))
          : const Text('Confirmer l\'approbation ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        TextButton(onPressed: () => Navigator.pop(context, needReason ? ctrl.text.trim() : ''), child: const Text('Valider')),
      ],
    );
  }
}
