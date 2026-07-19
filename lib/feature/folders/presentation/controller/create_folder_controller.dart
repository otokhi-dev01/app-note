import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../notes/presentation/controllers/home_controller.dart';

class CreateFolderController
    extends GetxController {
  final HomeController homeController;

  CreateFolderController({
    required this.homeController,
  });

  final TextEditingController nameController =
  TextEditingController();

  final RxString selectedIcon =
      'folder'.obs;

  final RxString selectedColor =
      '#5B7CFA'.obs;

  final RxBool isSaving = false.obs;

  final RxString errorMessage = ''.obs;

  final List<String> availableIcons =
  <String>[
    'folder',
    'work',
    'school',
    'personal',
    'favorite',
    'travel',
  ];

  final List<String> availableColors =
  <String>[
    '#5B7CFA',
    '#7C4DFF',
    '#EC407A',
    '#FF7043',
    '#26A69A',
    '#42A5F5',
    '#66BB6A',
    '#FFA726',
  ];

  Future<void> saveFolder() async {
    FocusManager.instance.primaryFocus
        ?.unfocus();

    final String name =
    nameController.text.trim();

    if (name.isEmpty) {
      errorMessage.value =
      'Please enter a folder name.';
      return;
    }

    try {
      isSaving.value = true;
      errorMessage.value = '';

      final bool success =
      await homeController.createFolder(
        name: name,
        iconName: selectedIcon.value,
        colorValue: selectedColor.value,
      );

      if (success) {
        Get.back<bool>(result: true);
      }
    } finally {
      isSaving.value = false;
    }
  }

  void selectIcon(String iconName) {
    selectedIcon.value = iconName;
  }

  void selectColor(String colorValue) {
    selectedColor.value = colorValue;
  }

  IconData iconData(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work_outline_rounded;

      case 'school':
        return Icons.school_outlined;

      case 'personal':
        return Icons.person_outline_rounded;

      case 'favorite':
        return Icons.favorite_border_rounded;

      case 'travel':
        return Icons.flight_takeoff_rounded;

      default:
        return Icons.folder_outlined;
    }
  }

  Color colorFromHex(String value) {
    try {
      String hex = value.replaceAll('#', '');

      if (hex.length == 6) {
        hex = 'FF$hex';
      }

      return Color(
        int.parse(hex, radix: 16),
      );
    } catch (_) {
      return const Color(0xFF5B7CFA);
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }
}