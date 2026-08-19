import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

class FolderSectionHeader extends StatelessWidget {
  final String title;
  final RxBool isExpanded;
  final VoidCallback onTap;

  /// Shows a "+" button on the right when set — omitted for sections (like
  /// "Sources") that aren't a place a new folder can be created into.
  final VoidCallback? onCreateFolder;

  const FolderSectionHeader({
    super.key,
    required this.title,
    required this.isExpanded,
    required this.onTap,
    this.onCreateFolder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: CustomGlassContainer(
        borderRadius: 20,
        blur: 14,
        opacity: 0.12,
        thickness: 6,
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(title, style: theme.textTheme.titleLarge),
                    ),
                    Obx(
                      () => CustomGlassContainer(
                        width: 36,
                        height: 36,
                        shape: GlassShape.circle,
                        blur: 10,
                        opacity: 0.15,
                        thickness: 8,
                        padding: EdgeInsets.zero,
                        alignment: Alignment.center,
                        child: Icon(
                          isExpanded.value
                              ? CupertinoIcons.chevron_down
                              : CupertinoIcons.chevron_forward,
                          color: AppTheme.folderPink,
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onCreateFolder != null) ...[
              const SizedBox(width: 8),
              CustomGlassButton(
                onPressed: onCreateFolder,
                semanticLabel: 'Create folder in $title',
                width: 36,
                height: 36,
                shape: GlassShape.circle,
                blur: 10,
                opacity: 0.15,
                thickness: 8,
                padding: EdgeInsets.zero,
                child: Icon(
                  CupertinoIcons.folder_badge_plus,
                  color: AppTheme.folderPink,
                  size: 25,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
