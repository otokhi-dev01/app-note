import 'package:Note/app/widgets/glass_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';
import '../controllers/splash_controller.dart';

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
                  Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.black54
                                  : Colors.black.withValues(alpha: 0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/icons/otokhi_logo_cover.jpg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.folderYellow,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.surface,
                                    width: 3,
                                  ),
                                ),
                                child: FaIcon(
                                  FontAwesomeIcons.penNib,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ).animate().scale(
                              delay: 1200.ms,
                              duration: 400.ms,
                              curve: Curves.easeOutBack,
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .scale(
                        duration: 1000.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1, 1),
                      )
                      .fadeIn(duration: 600.ms)
                      .shimmer(delay: 1500.ms, duration: 2000.ms),
                  const SizedBox(height: 40),
                  Text(
                        "OTOKHI NOTE",
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
                          "High Fidelity Note Taking",
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
