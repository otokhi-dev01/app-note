import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:Note/shared/widgets/app_logo.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: theme.scaffoldBackgroundColor,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: theme.scaffoldBackgroundColor,
            ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopSection(context),
              Expanded(
                child: PageView.builder(
                  controller: controller.pageController,
                  onPageChanged: controller.onPageChanged,
                  physics: const BouncingScrollPhysics(),
                  itemCount: controller.pages.length,
                  itemBuilder: (context, index) {
                    final page = controller.pages[index];

                    return _buildOnboardingPage(
                      context,
                      icon: page.icon,
                      title: page.title,
                      description: page.description,
                    );
                  },
                ),
              ),
              _buildBottomSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 4),
      child: Row(
        children: [
          const AppLogo(height: 40)
              .animate()
              .scale(
                duration: 600.ms,
                curve: Curves.easeOutBack,
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
              )
              .fadeIn(duration: 400.ms),
          const SizedBox(width: 12),
          Text(
            'Pii Note',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final illustrationSize = (constraints.maxWidth * 0.68).clamp(
          220.0,
          300.0,
        );

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIllustration(
                    context,
                    icon: icon,
                    size: illustrationSize,
                  ),
                  const SizedBox(height: 44),
                  Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontSize: 32,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: theme.colorScheme.onSurface,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 150.ms)
                      .slideY(
                        begin: 0.15,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Text(
                          description,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 17,
                            height: 1.55,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 300.ms)
                      .slideY(
                        begin: 0.12,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIllustration(
    BuildContext context, {
    required IconData icon,
    required double size,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: -0.09,
                child: Container(
                  width: size * 0.58,
                  height: size * 0.68,
                  decoration: BoxDecoration(
                    color: AppTheme.folderPink.withValues(
                      alpha: isDark ? 0.14 : 0.18,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              Container(
                width: size * 0.58,
                height: size * 0.68,
                padding: EdgeInsets.all(size * 0.09),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.45,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.20 : 0.07,
                      ),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: size * 0.24,
                      height: size * 0.24,
                      decoration: BoxDecoration(
                        color: AppTheme.folderPink.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        icon,
                        size: size * 0.13,
                        color: AppTheme.folderPink,
                      ),
                    ),
                    const Spacer(),
                    _buildNoteLine(context, width: double.infinity),
                    SizedBox(height: size * 0.035),
                    _buildNoteLine(context, width: size * 0.31),
                    SizedBox(height: size * 0.035),
                    _buildNoteLine(context, width: size * 0.23),
                  ],
                ),
              ),
              Positioned(
                top: size * 0.14,
                right: size * 0.14,
                child: Container(
                  width: size * 0.17,
                  height: size * 0.17,
                  decoration: BoxDecoration(
                    color: AppTheme.folderPink,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.folderPink.withValues(alpha: 0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: AppTheme.bodyColor,
                    size: size * 0.085,
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(
          begin: const Offset(0.88, 0.88),
          end: const Offset(1, 1),
          duration: 650.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildNoteLine(BuildContext context, {required double width}) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: 9,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Every action a first-run visitor could want — guest, sign in, or
  /// register — sits here, unconditionally, on every onboarding page. App
  /// Store guideline 5.1.1(v) requires that non-account features stay
  /// reachable without registering; putting "Continue without account" as
  /// the same kind of primary, full-width button as the other two (rather
  /// than a smaller de-emphasized link below a "Next" CTA) makes that an
  /// equally obvious choice instead of one a reviewer has to notice.
  Widget _buildBottomSection(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(controller.pages.length, (index) {
                final isActive = controller.currentPage.value == index;

                return AnimatedContainer(
                  duration: 300.ms,
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3.5),
                  width: isActive ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.folderPink
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.18,
                          ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.continueWithoutAccount,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                elevation: 0,
                backgroundColor: AppTheme.folderPink,
                foregroundColor: AppTheme.bodyColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'onboarding_continue_guest'.tr,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: controller.goToLogin,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                foregroundColor: AppTheme.folderPink,
                side: const BorderSide(color: AppTheme.folderPink, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'login_title'.tr,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          TextButton(
            onPressed: controller.goToRegister,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              minimumSize: const Size(double.infinity, 44),
            ),
            child: Text(
              'onboarding_create_account'.tr,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
