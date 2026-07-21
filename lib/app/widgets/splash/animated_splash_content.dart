import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/splash_controller.dart';
import 'splash_animated_logo.dart';
import 'splash_background_decoration.dart';
import 'splash_error_status.dart';
import 'splash_loading_status.dart';

class AnimatedSplashContent extends StatefulWidget {
  const AnimatedSplashContent({required this.controller, super.key});

  final SplashController controller;

  @override
  State<AnimatedSplashContent> createState() => _AnimatedSplashContentState();
}

class _AnimatedSplashContentState extends State<AnimatedSplashContent>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.75, end: 1).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
        );

    _introController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
            colors.surface,
            colors.secondary.withValues(alpha: isDark ? 0.08 : 0.05),
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          const SplashBackgroundDecoration(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: SplashAnimatedLogo(
                            pulseAnimation: _pulseController,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Piisiit Note',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Capture your ideas and keep\neverything organized.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Obx(
                          () => AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: Tween<double>(
                                        begin: 0.95,
                                        end: 1,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                            child: widget.controller.errorMessage.value.isEmpty
                                ? const SplashLoadingStatus(
                                    key: ValueKey<String>('loading'),
                                  )
                                : SplashErrorStatus(
                                    key: const ValueKey<String>('error'),
                                    message:
                                        widget.controller.errorMessage.value,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Simple • Secure • Organized',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.65),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
