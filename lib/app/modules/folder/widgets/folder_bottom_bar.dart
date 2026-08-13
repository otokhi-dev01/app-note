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
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: theme.brightness == Brightness.dark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                  ),
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
              thickness: 10,
              refractiveIndex: 1.3,
              opacity: 0.15,
              child: IconButton(
                onPressed: () => controller.createNewNote(),
                padding: EdgeInsets.zero,
                icon: Icon(
                  CupertinoIcons.square_pencil,
                  color: theme.colorScheme.onSurface,
                  size: 27,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
