import 'package:flutter/material.dart';

import 'package:Note/shared/widgets/glass_widgets.dart';

/// Compact glass frame shared by Folder view icons.
class FolderGlassIcon extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double size;
  final double borderRadius;

  const FolderGlassIcon({
    super.key,
    required this.child,
    this.color,
    this.size = 40,
    this.borderRadius = 11,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;

    return CustomGlassContainer(
      width: size,
      height: size,
      borderRadius: borderRadius,
      blur: 12,
      opacity: 0.12,
      thickness: 6,
      refractiveIndex: 1.1,
      glassColor: accent.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: child,
    );
  }
}
