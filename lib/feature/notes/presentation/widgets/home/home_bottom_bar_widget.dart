import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import 'glass_surface_widget.dart';

part 'bottom_bar_content_widget.dart';

class HomeBottomBar extends GetView<HomeController> {
  final VoidCallback onCreateNote;

  const HomeBottomBar({super.key, required this.onCreateNote});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool canCreateNote = controller.folders.isNotEmpty;

      final String folderName = controller.selectedFolderName;

      return _BottomBarContent(
        folderName: folderName,
        canCreateNote: canCreateNote,
        onCreateNote: onCreateNote,
      );
    });
  }
}
