import 'package:flutter/material.dart';

class SettingsFlagWidget extends StatelessWidget {
  const SettingsFlagWidget({
    super.key,
    required this.assetPath,
    required this.fallbackFlag,
  });

  final String assetPath;
  final String fallbackFlag;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surface,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                return Center(
                  child: Text(
                    fallbackFlag,
                    style: const TextStyle(fontSize: 27),
                  ),
                );
              },
        ),
      ),
    );
  }
}
