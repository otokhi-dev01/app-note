import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import 'glass_surface_widget.dart';

part 'header_content_widget.dart';
part 'glass_icon_button_widget.dart';

class HomeHeader extends GetView<HomeController> {
  final VoidCallback onOpenFolders;
  final VoidCallback onOpenMenu;

  const HomeHeader({
    super.key,
    required this.onOpenFolders,
    required this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isLoading =
          controller.isNotesLoading.value || controller.isFoldersLoading.value;

      return GlassSurface(
        padding: const EdgeInsets.fromLTRB(18, 15, 10, 15),
        child: _HeaderContent(
          title: controller.selectedFolderName,
          noteCount: controller.selectedFolderNoteCount,
          isLoading: isLoading,
          onOpenFolders: onOpenFolders,
          onRefresh: controller.loadAll,
          onOpenMenu: onOpenMenu,
        ),
      );
    });
  }
}
