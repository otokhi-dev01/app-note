import 'package:flutter/material.dart';

class NoteActionSheetRow extends StatelessWidget {
  const NoteActionSheetRow({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 20),
        const SizedBox(width: 9),
        Text(label),
      ],
    );
  }
}
