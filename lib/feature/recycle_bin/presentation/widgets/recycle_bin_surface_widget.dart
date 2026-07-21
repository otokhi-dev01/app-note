import 'package:flutter/material.dart';

class RecycleBinSurfaceWidget extends StatelessWidget {
  const RecycleBinSurfaceWidget({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: padding,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: isDark
            ? const <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.06),
                  blurRadius: 18,
                  spreadRadius: -9,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );
  }
}
