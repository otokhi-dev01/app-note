import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainNavigationController extends GetxController {
  static const int screenCount = 4;
  static const int navItemCount = 5;

  final RxInt selectedIndex = 0.obs;

  late final PageController pageController;

  @override
  void onInit() {
    super.onInit();

    pageController = PageController(initialPage: selectedIndex.value);
  }

  double get currentPage {
    if (!pageController.hasClients) {
      return selectedIndex.value.toDouble();
    }

    return pageController.page ?? selectedIndex.value.toDouble();
  }

  Future<void> changeTab(int navIndex) async {
    if (navIndex < 0 || navIndex >= navItemCount) {
      return;
    }

    if (navIndex == 2) {
      // Index 2 is the Create Note action, not a screen.
      return;
    }

    if (navIndex == selectedIndex.value) {
      return;
    }

    selectedIndex.value = navIndex;

    if (!pageController.hasClients) {
      return;
    }

    final int screenIndex = navIndex < 2 ? navIndex : navIndex - 1;

    await pageController.animateToPage(
      screenIndex,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void onPageChanged(int screenIndex) {
    if (screenIndex < 0 || screenIndex >= screenCount) {
      return;
    }

    // Map screen index back to nav index (0, 1 -> 0, 1; 2, 3 -> 3, 4)
    selectedIndex.value = screenIndex < 2 ? screenIndex : screenIndex + 1;
  }

  @override
  void onClose() {
    pageController.dispose();

    super.onClose();
  }
}
