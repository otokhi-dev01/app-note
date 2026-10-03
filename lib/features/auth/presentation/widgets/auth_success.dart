import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

import 'package:Note/shared/widgets/glass_widgets.dart';

/// Shared confirmation for completed authentication flows.
class AuthSuccess extends StatelessWidget {
  const AuthSuccess({
    super.key,
    required this.title,
    required this.description,
    required this.onDone,
  });

  final String title;
  final String description;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onDone();
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: CustomGlassContainer(
                              width: double.infinity,
                              borderRadius: 28,
                              blur: 35,
                              opacity: 0.12,
                              thickness: 16,
                              showGlow: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 36,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ExcludeSemantics(
                                    child: Container(
                                      width: 112,
                                      height: 112,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colors.primary.withValues(
                                          alpha: 0.06,
                                        ),
                                        border: Border.all(
                                          color: colors.primary,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colors.primary.withValues(
                                              alpha: 0.10,
                                            ),
                                            blurRadius: 36,
                                            spreadRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        CupertinoIcons.check_mark,
                                        size: 52,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  Semantics(
                                    header: true,
                                    liveRegion: true,
                                    child: Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            color: colors.onSurface,
                                            fontWeight: FontWeight.w700,
                                            height: 1.35,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    description,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 16,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CustomGlassButton(
                    semanticLabel: 'done_action'.tr,
                    onPressed: onDone,
                    minHeight: 56,
                    borderRadius: 28,
                    style: lg.GlassButtonStyle.prominent,
                    glassColor: colors.primary,
                    glowColor: colors.primary,
                    foregroundColor: Colors.white,
                    child: Text(
                      'done_action'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
