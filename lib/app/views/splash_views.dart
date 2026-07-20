import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/splash_controllers.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AnimatedSplashContent(
        controller: controller,
      ),
    );
  }
}

class _AnimatedSplashContent extends StatefulWidget {
  final SplashController controller;

  const _AnimatedSplashContent({
    required this.controller,
  });

  @override
  State<_AnimatedSplashContent> createState() =>
      _AnimatedSplashContentState();
}

class _AnimatedSplashContentState extends State<_AnimatedSplashContent>
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

    _scaleAnimation = Tween<double>(
      begin: 0.75,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutBack,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutCubic,
      ),
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
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(
              isDark ? 0.12 : 0.08,
            ),
            colorScheme.surface,
            colorScheme.secondary.withOpacity(
              isDark ? 0.08 : 0.05,
            ),
          ],
        ),
      ),
      child: Stack(
        children: [
          _BackgroundDecoration(
            colorScheme: colorScheme,
          ),
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
                      children: [
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: _AnimatedLogo(
                            pulseController: _pulseController,
                            colorScheme: colorScheme,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Piisiit Note',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Capture your ideas and keep\neverything organized.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Obx(
                              () => AnimatedSwitcher(
                            duration: const Duration(
                              milliseconds: 350,
                            ),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (
                                Widget child,
                                Animation<double> animation,
                                ) {
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
                            child: widget
                                .controller
                                .errorMessage
                                .value
                                .isEmpty
                                ? _LoadingStatus(
                              key: const ValueKey('loading'),
                              colorScheme: colorScheme,
                              theme: theme,
                              isDark: isDark,
                            )
                                : _ErrorStatus(
                              key: const ValueKey('error'),
                              message: widget
                                  .controller
                                  .errorMessage
                                  .value,
                              colorScheme: colorScheme,
                              theme: theme,
                              isDark: isDark,
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
                  color: colorScheme.onSurfaceVariant.withOpacity(0.65),
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

class _AnimatedLogo extends StatelessWidget {
  final AnimationController pulseController;
  final ColorScheme colorScheme;
  final bool isDark;

  const _AnimatedLogo({
    required this.pulseController,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        final double value = pulseController.value;
        final double scale = 1 + (value * 0.04);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.72),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(
                  isDark ? 0.12 : 0.30,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(
                    0.18 + (value * 0.12),
                  ),
                  blurRadius: 30 + (value * 12),
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 14,
                  right: 18,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                ),
                Icon(
                  Icons.note_alt_rounded,
                  size: 66,
                  color: colorScheme.onPrimary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoadingStatus extends StatelessWidget {
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isDark;

  const _LoadingStatus({
    super.key,
    required this.colorScheme,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1B1D22)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              isDark ? 0.12 : 0.05,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: colorScheme.primary,
              backgroundColor: colorScheme.primary.withOpacity(0.12),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Starting application...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorStatus extends StatelessWidget {
  final String message;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isDark;

  const _ErrorStatus({
    super.key,
    required this.message,
    required this.colorScheme,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 360,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1B1D22)
            : colorScheme.errorContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorScheme.error.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 21,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundDecoration extends StatelessWidget {
  final ColorScheme colorScheme;

  const _BackgroundDecoration({
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _GlowCircle(
              size: 230,
              color: colorScheme.primary.withOpacity(0.07),
            ),
          ),
          Positioned(
            left: -100,
            bottom: 40,
            child: _GlowCircle(
              size: 260,
              color: colorScheme.secondary.withOpacity(0.06),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}