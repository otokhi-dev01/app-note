import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/folder_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_widgets.dart';

class NoteMoveFolderModal extends StatelessWidget {
  final List<FolderModel> folders;
  final int currentFolderId;
  final Function(FolderModel) onFolderSelected;
  final VoidCallback? onCreateNewFolder;

  const NoteMoveFolderModal({
    super.key,
    required this.folders,
    required this.currentFolderId,
    required this.onFolderSelected,
    this.onCreateNewFolder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentFolder = folders.firstWhereOrNull(
      (f) => f.id == currentFolderId,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomGlassContainer(
        borderRadius: 30,
        blur: 35,
        opacity: 0.1,
        thickness: 10,
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            // Header: Standard iOS style with X on the left
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 55, 16, 8),
              child: Row(
                children: [
                  CustomGlassContainer(
                    width: 44,
                    height: 44,
                    shape: GlassShape.circle,
                    opacity: 0.1,
                    blur: 10,
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        CupertinoIcons.xmark,
                        color: isDark ? Colors.white : Colors.black,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Select a Folder",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Current Folder Section ──
                    if (currentFolder != null) ...[
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.folder,
                            color: AppTheme.folderPink,
                            size: 56,
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentFolder.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              Text(
                                "${currentFolder.noteCount} Notes",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],

                    // ── Section Header: On My iPhone ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "On My iPhone",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.chevron_down,
                          color: AppTheme.folderPink,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Folders Container (Glassy Rounded Card) ──
                    CustomGlassContainer(
                      borderRadius: 28,
                      opacity: 0.05,
                      blur: 10,
                      thickness: 5,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // New Folder Action Tile
                          _buildActionTile(
                            icon: CupertinoIcons.folder_badge_plus,
                            label: "New Folder",
                            onTap: onCreateNewFolder ?? () {},
                          ),
                          Divider(
                            indent: 64,
                            height: 1,
                            thickness: 0.5,
                            color: theme.dividerColor.withValues(alpha: 0.1),
                          ),

                          // List of available folders
                          for (int i = 0; i < folders.length; i++) ...[
                            _buildFolderTile(context, folders[i]),
                            if (i < folders.length - 1)
                              Divider(
                                indent: 64,
                                height: 1,
                                thickness: 0.5,
                                color: theme.dividerColor.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
      leading: Icon(icon, color: AppTheme.folderPink, size: 28),
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

  Widget _buildFolderTile(BuildContext context, FolderModel folder) {
    final theme = Theme.of(context);
    final isCurrent = folder.id == currentFolderId;
    final isSystem = ["Notes", "All on My iPhone"].contains(folder.name);

    return Opacity(
      opacity: isCurrent ? 0.35 : 1.0,
      child: CustomGlassListTile(
        onTap: isCurrent ? null : () => onFolderSelected(folder),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: const Icon(
          CupertinoIcons.folder,
          color: AppTheme.folderPink,
          size: 26,
        ),
        title: Text(
          folder.name,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.3,
            color: isSystem ? Colors.grey : theme.colorScheme.onSurface,
          ),
        ),
        trailing: isCurrent
            ? const Icon(
                CupertinoIcons.checkmark,
                color: AppTheme.folderPink,
                size: 18,
              )
            : Icon(
                CupertinoIcons.chevron_forward,
                color: Colors.grey.withValues(alpha: 0.3),
                size: 16,
              ),
      ),
    );
  }
}
