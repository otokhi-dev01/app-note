import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/core/presentation/brand/app_brand.dart';
import 'package:notes/core/presentation/animations/fade_in_widget.dart';
import 'package:notes/features/startup/presentation/controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _SplashBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 430;
              return Stack(
                children: [
                  Center(
                    child: FadeInWidget(
                      duration: const Duration(milliseconds: 800),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppBrandLogo(
                            height: compact ? 104 : 154,
                            borderRadius: compact ? 22 : 30,
                          ),
                          SizedBox(height: compact ? 16 : 32),
                          Text(
                            'P NOTE',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.onSurface,
                              fontSize: compact ? 15 : 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3.2,
                            ),
                          ),
                          SizedBox(height: compact ? 6 : 10),
                          Text(
                            'Capture what matters.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                              letterSpacing: -0.1,
                            ),
                          ),
                          SizedBox(height: compact ? 18 : 34),
                          Container(
                            width: 46,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHigh.withValues(
                                alpha: isDark ? 0.72 : 0.64,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: colors.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                                width: 0.5,
                              ),
                            ),
                            child: CupertinoActivityIndicator(
                              radius: 9,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!compact)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: FadeInWidget(
                        duration: const Duration(milliseconds: 1500),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.lock_shield_fill,
                                size: 14,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Secure Account',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppBrandBackdrop(child: child);
  }
}
