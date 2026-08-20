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
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Text(title, style: theme.textTheme.titleLarge),
              ),
            ),
            if (onCreateFolder != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onCreateFolder,
                tooltip: 'Create folder in $title',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                icon: Icon(
                  CupertinoIcons.folder_badge_plus,
                  color: AppTheme.folderPink,
                  size: 25,
                ),
              ),
            ],
            // Last in the row, after the "+", so the arrow lands in the same
            // place on every section header. Sections with no "+" of their own
            // (Sources) already put it there, so keeping it ahead of the button
            // on the two that do left the arrows unaligned down the column.
            _SectionExpandToggle(isExpanded: isExpanded, onTap: onTap),
          ],
        ),
      ),
    );
  }
}

/// The section's disclosure arrow.
///
/// Same glyph and rotate-on-expand behavior as the one on a folder row with
/// subfolders (`_ExpandToggle` in folder_tile.dart) — a section is the same
/// idea one level up, so it should not read as a different control. It keeps
/// its own tap target rather than riding on the title's: the "+" now sits
/// between the two, so one gesture area can no longer span both.
class _SectionExpandToggle extends StatelessWidget {
  final RxBool isExpanded;
  final VoidCallback onTap;

  const _SectionExpandToggle({required this.isExpanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: AnimatedRotation(
              turns: isExpanded.value ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.folderPink,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
