import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/theme/app_colors.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

/// What the user picked in [FolderLocationPickerModal]: `parentId == null`
/// means the top level ("On My iPhone"), distinct from a cancelled pick
/// (which resolves the pushed route with no result at all).
class ParentSelection {
  final int? parentId;
  const ParentSelection(this.parentId);
}

/// iOS-Notes-style "Location" screen: an indented list of every folder the
/// one being created/edited could nest under, plus "On My iPhone" for the
/// top level. Tapping a row picks it and pops immediately.
class FolderLocationPickerModal extends StatelessWidget {
  final FolderController controller;
  final int? currentParentId;

  /// The folder being edited, if any — it and its whole subtree are hidden
  /// so a folder can't be moved inside itself.
  final int? excludeFolderId;

  const FolderLocationPickerModal({
    super.key,
    required this.controller,
    required this.currentParentId,
    this.excludeFolderId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = AppColors.isDark(context);

    final excluded = excludeFolderId != null
        ? controller.subtreeIds(excludeFolderId!)
        : const <int>{};
    final visible = controller.folders
        .where(
          (f) => !excluded.contains(f.id) && !controller.isSystemFolder(f),
        )
        .toList();
    final tree = controller.buildHierarchy(visible);

    final rows = <_LocationRow>[];
    void flatten(List<Folder> level, int depth) {
      for (final folder in level) {
        rows.add(_LocationRow(folder, depth));
        if (folder.subFolders.isNotEmpty) {
          flatten(folder.subFolders, depth + 1);
        }
      }
    }

    flatten(tree, 0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
      child: Scaffold(
        backgroundColor: colors.background,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              sliver: SliverToBoxAdapter(
                child: GlassCard(
                  borderRadius: 28,
                  children: [
                    _buildRootTile(context, colors),
                    if (rows.isNotEmpty)
                      Divider(
                        indent: 56,
                        height: 1,
                        thickness: 0.5,
                        color: colors.divider.withValues(alpha: 0.5),
                      ),
                    for (int i = 0; i < rows.length; i++) ...[
                      _buildFolderTile(context, colors, rows[i]),
                      if (i < rows.length - 1)
                        Divider(
                          indent: 56,
                          height: 1,
                          thickness: 0.5,
                          color: colors.divider.withValues(alpha: 0.5),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.paddingOf(context).bottom + 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return CustomGlassSliverAppBar(
      expandedHeight: 140,
      toolbarHeight: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      centerTitle: true,
      title: Text(
        "Location",
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
      ),
      leading: CustomGlassButton(
        onPressed: () => Get.back(),
        semanticLabel: 'Cancel',
        width: 44,
        height: 44,
        shape: GlassShape.circle,
        blur: 10,
        opacity: 0.15,
        thickness: 8,
        padding: EdgeInsets.zero,
        child: Icon(
          CupertinoIcons.chevron_left,
          color: theme.colorScheme.onSurface,
          size: 24,
        ),
      ),
      largeTitleAlignment: Alignment.bottomLeft,
      largeTitlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
      largeTitle: Text(
        "Location",
        style: theme.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 34,
        ),
      ),
    );
  }

  Widget _buildRootTile(BuildContext context, AppColors colors) {
    final selected = currentParentId == null;
    return CustomGlassListTile(
      onTap: () {
        HapticFeedback.selectionClick();
        Get.back(result: const ParentSelection(null));
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(
        CupertinoIcons.device_phone_portrait,
        color: colors.mutedIcon,
        size: 24,
      ),
      title: Text(
        "On My iPhone",
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.3,
          color: colors.primaryText,
        ),
      ),
      trailing: selected
          ? Icon(
              CupertinoIcons.checkmark,
              color: Theme.of(context).primaryColor,
              size: 18,
            )
          : Icon(
              CupertinoIcons.chevron_forward,
              color: colors.mutedIcon.withValues(alpha: 0.3),
              size: 16,
            ),
    );
  }

  Widget _buildFolderTile(
    BuildContext context,
    AppColors colors,
    _LocationRow row,
  ) {
    final folder = row.folder;
    final selected = folder.id == currentParentId;
    return CustomGlassListTile(
      onTap: () {
        HapticFeedback.selectionClick();
        Get.back(result: ParentSelection(folder.id));
      },
      contentPadding: EdgeInsets.only(
        left: 20.0 + row.depth * 20.0,
        right: 20,
        top: 4,
        bottom: 4,
      ),
      leading: FolderGlyph(folder: folder, size: 26),
      title: Text(
        folder.displayName,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.3,
          color: colors.primaryText,
        ),
      ),
      trailing: selected
          ? Icon(CupertinoIcons.checkmark, color: folder.color, size: 18)
          : Icon(
              CupertinoIcons.chevron_forward,
              color: colors.mutedIcon.withValues(alpha: 0.3),
              size: 16,
            ),
    );
  }
}

class _LocationRow {
  final Folder folder;
  final int depth;
  const _LocationRow(this.folder, this.depth);
}
