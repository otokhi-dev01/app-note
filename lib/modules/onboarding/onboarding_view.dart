import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../app/services/storage_service.dart';
import '../../app/theme/colors.dart';
import '../../core/widgets/decorative_background.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/liquid_glass_container.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < _items.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      } else {
        // Loop back to the first page when reaching the end
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _startAutoScroll();
  }

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Organize with Folders',
      description: 'Group your notes seamlessly and keep your workspace clutter-free.',
      icon: Icons.folder_copy_rounded,
      color: AppColors.accent
    ),
    OnboardingItem(
      title: 'Quick Search',
      description: 'Find what you need in seconds with powerful search and filters.',
      icon: Icons.search_rounded,
      color: AppColors.accent
    ),
    OnboardingItem(
      title: 'Secure & Synced',
      description: 'Your notes are encrypted and available on all your devices.',
      icon: Icons.security_rounded,
      color: AppColors.accent
    ),
  ];

  void _onNext() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _resetTimer();
    } else {
      Get.find<StorageService>().isFirstTime = false;
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecorativeBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
              onPressed: () {
        Get.find<StorageService>().isFirstTime = false;
        Get.offAllNamed(AppRoutes.login);
        },
          child: const Text(
            'Skip',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold, // Makes the text bold
            ),
          ),
        ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    _resetTimer();
                  },
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 500),
                            tween: Tween(begin: 0, end: 1),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) => Transform.scale(
                              scale: value,
                              child: child,
                            ),
                            child: LiquidGlassContainer(
                              borderRadius: BorderRadius.circular(40),
                              padding: const EdgeInsets.all(40),
                              opacity: 0.6,
                              blur: 10,
                              child: Icon(
                                _items[index].icon,
                                size: 80,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 60),
                          Text(
                            _items[index].title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _items[index].description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary.withValues(alpha: 0.8),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _items.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppColors.primary
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    AppButton(
                      onPressed: _onNext,
                      text: _currentPage == _items.length - 1 ? 'Get Started' : 'Next',
                      icon: _currentPage == _items.length - 1 ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// crate class onboarding screen
class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color
  });
}
