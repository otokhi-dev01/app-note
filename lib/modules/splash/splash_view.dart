import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/widgets/liquid_glass_container.dart';
import 'splash_controller.dart';
import '../../app/theme/colors.dart';
import '../../core/widgets/decorative_background.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller is already being used to navigate after delay
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecorativeBackground(
        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 1),
            tween: Tween(begin: 0, end: 1),
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: value,
                child: child,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    'assets/icons/logo_icon.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'OTOKHI NOTES',
                  style: TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Capture clarity.',
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 2,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 80),
                const SizedBox(
                  width: 40,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
