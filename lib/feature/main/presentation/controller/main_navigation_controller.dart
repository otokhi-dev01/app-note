import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainNavigationController extends GetxController {
  static const int tabCount = 4;

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

  Future<void> changeTab(int index) async {
    if (index < 0 || index >= tabCount) {
      return;
    }

    if (index == selectedIndex.value) {
      return;
    }

    selectedIndex.value = index;

    if (!pageController.hasClients) {
      return;
    }

    await pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void onPageChanged(int index) {
    if (index < 0 || index >= tabCount) {
      return;
    }

    selectedIndex.value = index;
  }

  @override
  void onClose() {
    pageController.dispose();

    super.onClose();
  }
}
