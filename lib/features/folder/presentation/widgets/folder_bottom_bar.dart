import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';

class FolderBottomBar extends StatelessWidget {
  final FolderController controller;

  const FolderBottomBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Same floating-pill footprint as the Search screen's bottom bar: a
    // wide "Search" pill plus a circular accent button, both detached from
    // the screen edges by the same outer padding.
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset > 0 ? 10 : 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: CustomGlassButton(
                onPressed: () => Get.toNamed(Routes.SEARCH),
                semanticLabel: 'Search notes and folders',
                height: 50,
                borderRadius: 30,
                blur: 10,
                opacity: 0.15,
                thickness: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Search',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 17,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Spacer(),
                    Icon(
                      CupertinoIcons.mic_fill,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            CustomGlassButton(
              onPressed: controller.createNewNote,
              semanticLabel: 'Create note',
              width: 50,
              height: 50,
              shape: GlassShape.circle,
              blur: 10,
              opacity: 0.15,
              thickness: 8,
              padding: EdgeInsets.zero,
              child: Icon(
                CupertinoIcons.square_pencil,
                color: theme.primaryColor,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
