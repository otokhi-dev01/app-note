import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/core/storage/settings_preferences.dart';
import 'package:Note/core/utils/attachment_url.dart';
import 'package:Note/core/utils/date_formatter.dart';
import 'package:Note/routes/note_navigation.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/note/presentation/controllers/note_controller.dart';
import 'package:Note/features/note/presentation/widgets/note_item_context_menu.dart';
import 'package:Note/core/utils/note_snippet.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/domain/entities/note.dart';

class NoteGridTile extends StatelessWidget {
  final Note note;
  final int folderId;
  final NoteController controller;

  const NoteGridTile({
    super.key,
    required this.note,
    required this.folderId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final visualBlock = note.content.firstWhereOrNull(
      (b) => b is AttachmentBlock || b is DrawingBlock,
    );

    return Obx(() {
      final isEditing = controller.isEditing.value;
      final isSelected = controller.isSelected(note.id);
      final hidePreview =
          Get.isRegistered<SettingsPreferences>() &&
          Get.find<SettingsPreferences>().hideNotePreviews.value;

      return NoteItemContextMenu(
        note: note,
        folderId: folderId,
        controller: controller,
        triggerBuilder: (context, openMenu) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (controller.isEditing.value) {
              controller.toggleSelectNote(note.id);
            } else {
              NoteNavigation.toDetail(
                note,
              )?.then((_) => controller.fetchNotes(folderId: folderId));
            }
          },
          onLongPress: controller.isEditing.value ? null : openMenu,
          child: CustomGlassContainer(
            borderRadius: 20,
            opacity: 0.1,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: _buildTopPreview(
                          context,
                          visualBlock,
                          hidePreview: hidePreview,
                        ),
                      ),
                    ),

                    Expanded(
                      flex: 2,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              note.displayTitle,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormatter.relative(note.updatedAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (note.attachmentCount > 0)
                                  Icon(
                                    CupertinoIcons.paperclip,
                                    size: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                if (isEditing)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? theme.colorScheme.onSurface
                            : Colors.black26,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: theme.colorScheme.surface,
                              size: 14,
                            )
                          : null,
                    ),
                  )
                else if (note.isPinned)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Icon(
                      Icons.push_pin,
                      color: theme.primaryColor,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTopPreview(
    BuildContext context,
    NoteBlock? visualBlock, {
    required bool hidePreview,
  }) {
    if (hidePreview) {
      return _GridPlaceholder(
        icon: CupertinoIcons.lock_shield,
        label: 'privacy_preview_hidden'.tr,
      );
    }

    if (visualBlock != null) {
      return _GridVisualPreview(block: visualBlock);
    }

    if (note.attachmentCount > 0) {
      return _GridPlaceholder(
        icon: CupertinoIcons.photo,
        label: "note_list_loading_image".tr,
      );
    }

    return _GridTextPreview(note: note);
  }
}

class _GridVisualPreview extends StatelessWidget {
  final NoteBlock block;

  const _GridVisualPreview({required this.block});

  @override
  Widget build(BuildContext context) {
    String? localPath;
    String? url;

    if (block is AttachmentBlock) {
      final b = block as AttachmentBlock;
      localPath = b.localPath;
      url = b.url;
    } else if (block is DrawingBlock) {
      final b = block as DrawingBlock;
      localPath = b.localPath;
      url = b.url;
    }

    final normalizedLocalPath = normalizeLocalPath(localPath);
    if (normalizedLocalPath != null && File(normalizedLocalPath).existsSync()) {
      return Image.file(
        File(normalizedLocalPath),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _GridPlaceholder(),
      );
    }

    final networkUrl = normalizeAttachmentUrl(url);
    if (networkUrl != null) {
      return Image.network(
        networkUrl,
        headers: attachmentAuthHeaders(),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).primaryColor,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => const _GridPlaceholder(),
      );
    }

    return const _GridPlaceholder();
  }
}

class _GridTextPreview extends StatelessWidget {
  final Note note;

  const _GridTextPreview({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snippet = NoteSnippet.preview(note);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
      child: Text(
        snippet,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          height: 1.3,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        maxLines: 8,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _GridPlaceholder extends StatelessWidget {
  final IconData icon;
  final String? label;

  const _GridPlaceholder({this.icon = CupertinoIcons.photo, this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          if (label != null) ...[
            const SizedBox(height: 8),
            Text(
              label!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
