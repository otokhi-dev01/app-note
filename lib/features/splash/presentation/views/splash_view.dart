import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/features/splash/presentation/controllers/splash_controller.dart';
import 'package:Note/shared/widgets/app_logo.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogo(height: 120, showGlow: true)
                      .animate()
                      .scale(
                        duration: 900.ms,
                        curve: Curves.easeOutBack,
                        begin: const Offset(0.86, 0.86),
                        end: const Offset(1, 1),
                      )
                      .fadeIn(duration: 600.ms)
                      .shimmer(delay: 1400.ms, duration: 1800.ms),
                  const SizedBox(height: 36),
                  Text(
                        "PII NOTE",
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontSize: 36,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 800.ms, duration: 800.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
                ],
              ),
            ),
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.folderYellow,
                        ),
                      ),
                    ).animate().fadeIn(delay: 1200.ms),
                    const SizedBox(height: 16),
                    CustomGlassContainer(
                      width: 230,
                      borderRadius: 15,
                      thickness: 5,
                      opacity: 0.1,
                      child: Center(
                        child: Text(
                          "app_tagline".tr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                            letterSpacing: 0.5,
                            fontSize: 15,
                          ),
                        ).animate().fadeIn(delay: 1500.ms),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
