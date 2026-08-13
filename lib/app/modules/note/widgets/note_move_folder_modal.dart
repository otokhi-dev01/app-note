import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/folder_model.dart';
import '../../../theme/app_theme.dart';

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

    return Material( // Root Cause Fix: Wrap in Material to support ListTile
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF4F3F9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Header: Standard iOS style with X on the left
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 55, 16, 8),
              child: Row(
                children: [
                  _RoundActionButton(
                    icon: CupertinoIcons.xmark,
                    onTap: () => Get.back(),
                    backgroundColor: isDark ? Colors.white10 : Colors.white,
                    iconColor: isDark ? Colors.white : Colors.black,
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

                    // ── Folders Container (Standard iOS Rounded Card) ──
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
                        boxShadow: isDark ? null : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // New Folder Action Tile
                          _buildActionTile(
                            icon: CupertinoIcons.folder_badge_plus,
                            label: "New Folder",
                            onTap: onCreateNewFolder ?? () {},
                          ),
                          const Divider(indent: 64, height: 1, thickness: 0.5),

                          // List of available folders
                          for (int i = 0; i < folders.length; i++) ...[
                            _buildFolderTile(context, folders[i]),
                            if (i < folders.length - 1)
                              const Divider(indent: 64, height: 1, thickness: 0.5),
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
    return ListTile(
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
      child: ListTile(
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
          ? const Icon(CupertinoIcons.checkmark, color: AppTheme.folderPink, size: 18)
          : Icon(CupertinoIcons.chevron_forward, color: Colors.grey.withValues(alpha: 0.3), size: 16),
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;

  const _RoundActionButton({
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Center(
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ),
      ),
    );
  }
}
