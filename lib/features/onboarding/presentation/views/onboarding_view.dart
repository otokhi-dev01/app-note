import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/features/onboarding/presentation/controllers/onboarding_controller.dart';

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
          ClipOval(
            child: Image.asset(
              'assets/icons/otokhi_logo_cover.jpg',
              width: 60,
              height: 60,
              // fit: BoxFit.contain,
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(width: 11),
          Text(
            'OTOKHI',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Obx(() {
            final isLastPage =
                controller.currentPage.value == controller.pages.length - 1;

            if (isLastPage) {
              return const SizedBox(width: 70, height: 44);
            }

            return CustomGlassContainer(
              width: 70,
              height: 44,
              child: TextButton(
                onPressed: _skipToLastPage,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  minimumSize: const Size(70, 44),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Skip',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            );
          }),
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

  Widget _buildBottomSection(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => Row(
                    children: List.generate(controller.pages.length, (index) {
                      final isActive = controller.currentPage.value == index;

                      return AnimatedContainer(
                        duration: 300.ms,
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 7),
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
              ),
              Obx(() {
                final isLastPage =
                    controller.currentPage.value ==
                    controller.pages.length - 1;

                return ElevatedButton(
                  onPressed: controller.nextPage,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(138, 56),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    elevation: 0,
                    backgroundColor: AppTheme.folderPink,
                    foregroundColor: AppTheme.bodyColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: 220.ms,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.12, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Row(
                      key: ValueKey(isLastPage),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLastPage ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isLastPage
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          size: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          TextButton(
            onPressed: controller.continueWithoutAccount,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              minimumSize: const Size(double.infinity, 44),
            ),
            child: const Text(
              'Continue without account',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _skipToLastPage() {
    controller.pageController.animateToPage(
      controller.pages.length - 1,
      duration: 450.ms,
      curve: Curves.easeOutCubic,
    );
  }
}
