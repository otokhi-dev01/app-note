import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/glass_widgets.dart';
import '../controllers/folder_controller.dart';

class FolderBottomBar extends StatelessWidget {
  final FolderController controller;

  const FolderBottomBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Get.toNamed(Routes.SEARCH),
                child: LiquidGlassContainer(
                  thickness: 20,
                  refractiveIndex: 2,
                  opacity: 0.20,
                  height: 55,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Search",
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.mic,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            LiquidGlassContainer(
              width: 50,
              height: 50,
              shape: GlassShape.circle,
              showGlow: true,
              thickness: 20,
              refractiveIndex: 2,
              opacity: 0.20,
              child: IconButton(
                onPressed: () => controller.createNewNote(),
                padding: EdgeInsets.zero,
                icon: Icon(
                  CupertinoIcons.square_pencil,
                  color: theme.primaryColor,
                  size: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
