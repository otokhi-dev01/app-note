import 'package:flutter/material.dart';

class RecycleBinItemIconWidget extends StatelessWidget {
  const RecycleBinItemIconWidget({
    super.key,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 21, color: foregroundColor),
    );
  }
}
