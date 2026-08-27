import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/folder/presentation/widgets/folder_glass_icon.dart';
import 'package:Note/core/theme/app_colors.dart';
import 'package:Note/core/theme/folder_appearance.dart';

class NoteMoveFolderModal extends StatefulWidget {
  final List<Folder> folders;
  final int currentFolderId;
  final Function(Folder) onFolderSelected;
  final VoidCallback? onCreateNewFolder;

  const NoteMoveFolderModal({
    super.key,
    required this.folders,
    required this.currentFolderId,
    required this.onFolderSelected,
    this.onCreateNewFolder,
  });

  @override
  State<NoteMoveFolderModal> createState() => _NoteMoveFolderModalState();
}

class _NoteMoveFolderModalState extends State<NoteMoveFolderModal> {
  bool _isICloudExpanded = true;
  bool _isOnMyPhoneExpanded = true;

  List<Folder> get folders => widget.folders;
  int get currentFolderId => widget.currentFolderId;
  Function(Folder) get onFolderSelected => widget.onFolderSelected;
  VoidCallback? get onCreateNewFolder => widget.onCreateNewFolder;

  // Same "icloud" name-keyword convention the main Folders screen uses
  // (FolderController.iCloudFolders / onMyiPhoneFolders) — there's no
  // separate "Shared" group here, so anything not Pii Cloud falls under
  // "On My iPhone".
  List<Folder> get _iCloudFolders =>
      folders.where((f) => f.name.toLowerCase().contains('icloud')).toList();

  List<Folder> get _onMyPhoneFolders =>
      folders.where((f) => !f.name.toLowerCase().contains('icloud')).toList();

  void _toggleICloud() {
    HapticFeedback.selectionClick();
    setState(() => _isICloudExpanded = !_isICloudExpanded);
  }

  void _toggleOnMyPhone() {
    HapticFeedback.selectionClick();
    setState(() => _isOnMyPhoneExpanded = !_isOnMyPhoneExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = AppColors.isDark(context);

    final currentFolder = folders.firstWhereOrNull(
      (f) => f.id == currentFolderId,
    );

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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Current Folder Section ──
                    if (currentFolder != null) ...[
                      Row(
                        children: [
                          FolderGlassIcon(
                            color: currentFolder.color,
                            size: 72,
                            borderRadius: 22,
                            child: FolderGlyph(folder: currentFolder, size: 40),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _folderDisplayName(currentFolder),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                  color: colors.primaryText,
                                ),
                              ),
                              Text(
                                "note list folder note count".trParams({
                                  'count': '${currentFolder.noteCount}',
                                }),
                                style: TextStyle(
                                  color: colors.secondaryText,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],

                    // ── New Folder (always available, not tied to a section) ──
                    GlassCard(
                      borderRadius: 28,
                      children: [
                        _buildActionTile(
                          icon: CupertinoIcons.folder_badge_plus,
                          label: "note list new folder".tr,
                          onTap: onCreateNewFolder ?? () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildFolderSection(
                      context,
                      colors,
                      title: "note list Pii Cloud".tr,
                      folders: _iCloudFolders,
                      isExpanded: _isICloudExpanded,
                      onToggle: _toggleICloud,
                    ),
                    _buildFolderSection(
                      context,
                      colors,
                      title: "note list on my iphone".tr,
                      folders: _onMyPhoneFolders,
                      isExpanded: _isOnMyPhoneExpanded,
                      onToggle: _toggleOnMyPhone,
                    ),
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

  // ── Sliver app bar ─────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppScreenSliverAppBar(
      centerTitle: true,
      title: "note list select a folder".tr,
      leading: CustomGlassButton(
        onPressed: () => Get.back(),
        semanticLabel: 'note list back'.tr,
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
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return CustomGlassListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: FolderGlassIcon(
        color: AppTheme.folderPink,
        child: Icon(icon, color: AppTheme.folderPink, size: 21),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: AppTheme.folderPink,
          fontWeight: FontWeight.w500,
          fontSize: 17,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildFolderSection(
    BuildContext context,
    AppColors colors, {
    required String title,
    required List<Folder> folders,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    if (folders.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  FolderGlassIcon(
                    color: AppTheme.folderPink,
                    size: 32,
                    borderRadius: 9,
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      color: AppTheme.folderPink,
                      size: 21,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            GlassCard(
              borderRadius: 28,
              children: [
                for (int i = 0; i < folders.length; i++) ...[
                  _buildFolderTile(context, colors, folders[i]),
                  if (i < folders.length - 1)
                    Divider(
                      indent: 64,
                      height: 1,
                      thickness: 0.5,
                      color: colors.divider.withValues(alpha: 0.5),
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFolderTile(
    BuildContext context,
    AppColors colors,
    Folder folder,
  ) {
    final isCurrent = folder.id == currentFolderId;
    final normalizedName = folder.name.trim().toLowerCase();
    final isSystem = const {
      'notes',
      // 'on my iphone',
      'on my phone',
      // 'all on my iphone',
      'all on my phone',
    }.contains(normalizedName);

    return Opacity(
      opacity: isCurrent ? 0.35 : 1.0,
      child: CustomGlassListTile(
        onTap: isCurrent ? null : () => onFolderSelected(folder),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: FolderGlassIcon(
          color: folder.color,
          child: FolderGlyph(folder: folder, size: 22),
        ),
        title: Text(
          _folderDisplayName(folder),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.3,
            color: isSystem ? colors.mutedIcon : colors.primaryText,
          ),
        ),
        trailing: FolderGlassIcon(
          color: isCurrent ? folder.color : colors.mutedIcon,
          size: 30,
          borderRadius: 9,
          child: Icon(
            isCurrent
                ? CupertinoIcons.checkmark
                : CupertinoIcons.chevron_forward,
            color: isCurrent
                ? folder.color
                : colors.mutedIcon.withValues(alpha: 0.55),
            size: isCurrent ? 17 : 14,
          ),
        ),
      ),
    );
  }

  String _folderDisplayName(Folder folder) {
    return switch (folder.name.trim().toLowerCase()) {
      'on my iphone' || 'on my phone' => 'folder on my phone'.tr,
      'all on my iphone' || 'all on my phone' => 'folder all notes'.tr,
      _ => folder.displayName,
    };
  }
}
