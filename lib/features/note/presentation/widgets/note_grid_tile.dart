import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/core/feedback/app_dialogs.dart';
import 'package:Note/core/utils/attachment_url.dart';
import 'package:Note/core/utils/date_formatter.dart';
import 'package:Note/routes/note_navigation.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/ios_action_menu.dart';
import 'package:Note/features/note/presentation/controllers/note_controller.dart';
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

    // Find the first visual attachment (Image or Drawing)
    // Note.fromJson now ensures these exist even if blockId was missing
    final visualBlock = note.content.firstWhereOrNull(
      (b) => b is AttachmentBlock || b is DrawingBlock,
    );

    return Obx(() {
      final isEditing = controller.isEditing.value;
      final isSelected = controller.selectedNoteIds.contains(note.id);

      return GestureDetector(
        onTap: () {
          if (isEditing) {
            controller.toggleSelectNote(note.id);
          } else {
            NoteNavigation.toDetail(note)?.then((value) {
              if (value == true) {
                controller.fetchNotes(folderId: folderId);
              }
            });
          }
        },
        onLongPress: isEditing
            ? null
            : () =>
                  _showContextMenu(context), // Logic: Hold to show delete popup
        child: CustomGlassContainer(
          borderRadius: 20,
          opacity: 0.1,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Section: Image or Text Preview
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: _buildTopPreview(context, visualBlock),
                    ),
                  ),

                  // Bottom Section: Title and Metadata
                  Expanded(
                    flex: 2,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.3),
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

              // Selection Overlay
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
      );
    });
  }

  void _showContextMenu(BuildContext context) {
    IOSActionMenu.show(
      context: context,
      type: IOSMenuType.popup,
      title: "Note Options",
      actions: [
        IOSMenuAction(
          label: note.isPinned ? "Unpin Note" : "Pin Note",
          icon: note.isPinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
          onTap: () async {
            await controller.updateNoteState(note.id, isPinned: !note.isPinned);
            await controller.fetchNotes(folderId: folderId, refresh: true);
          },
        ),
        IOSMenuAction(
          label: "Move Note",
          icon: CupertinoIcons.folder_badge_plus,
          onTap: () {
            controller.selectOnly(note.id);
            controller.moveSelectedNotes(context, folderId);
          },
        ),
        IOSMenuAction(
          label: "Delete",
          icon: CupertinoIcons.trash,
          isDestructive: true,
          onTap: () async {
            if (await AppDialogs.confirmDeleteNotes(1)) {
              controller.selectOnly(note.id);
              await controller.deleteSelectedNotes(folderId);
            }
          },
        ),
      ],
    );
  }

  Widget _buildTopPreview(BuildContext context, NoteBlock? visualBlock) {
    if (visualBlock != null) {
      return _GridVisualPreview(block: visualBlock);
    }

    // Even if visualBlock is null, if the count > 0, we might have an image not yet parsed
    // (though Note fix should have caught it)
    if (note.attachmentCount > 0) {
      return const _GridPlaceholder(
        icon: CupertinoIcons.photo,
        label: "Loading Image...",
      );
    }

    // Default to text preview
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
        fit: BoxFit.cover, // Ensures the picture fills the top area fully
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
        fit: BoxFit.cover, // Show the picture as the primary visual
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
