import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import 'onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          PageView.builder(
            controller: controller.pageController,
            onPageChanged: controller.onPageChanged,
            itemCount: controller.pages.length,
            itemBuilder: (context, index) {
              final page = controller.pages[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 280,
                      width: 280,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          page.icon,
                          size: 100,
                          color: AppTheme.folderYellow,
                        ).animate().shake(duration: GetNumUtils(1).seconds),
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 60),
                    Text(
                      page.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(fontSize: 32),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 20),
                    Text(
                      page.description,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 17,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ),
              );
            },
          ),
          
          Positioned(
            bottom: 60,
            left: 32,
            right: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Row(
                  children: List.generate(
                    controller.pages.length,
                    (index) => AnimatedContainer(
                      duration: 300.ms,
                      margin: const EdgeInsets.only(right: 8),
                      width: controller.currentPage.value == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: controller.currentPage.value == index 
                            ? AppTheme.folderYellow 
                            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                )),
                
                ElevatedButton(
                  onPressed: controller.nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.folderYellow,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Obx(() => Text(
                    controller.currentPage.value == controller.pages.length - 1 
                        ? "Get Started" 
                        : "Next",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
