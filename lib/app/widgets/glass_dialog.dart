import 'package:flutter/material.dart';
import 'glass_widgets.dart';

class GlassDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;

  const GlassDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: LiquidGlassContainer(
          borderRadius: 24,
          blur: 30,
          opacity: 0.1,
          thickness: 10,
          showGlow: true,
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  content,
                  const SizedBox(height: 24),
                  if (actions != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions!,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
