import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/note_model.dart';
import '../../../routes/note_navigation.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_widgets.dart';
import '../controllers/note_controller.dart';

class NoteGridTile extends StatelessWidget {
  final NoteModel note;
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
    final attachment = note.content.firstWhereOrNull((b) => b is AttachmentBlock) as AttachmentBlock?;

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
        child: LiquidGlassContainer(
          borderRadius: 20,
          opacity: 0.1,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (attachment != null)
                    Expanded(
                      flex: 3,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: _GridImage(attachment: attachment),
                      ),
                    )
                  else
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          color: Colors.white10,
                        ),
                        child: Text(
                          _getContentSnippet(note),
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
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
                          Text(
                            _formatTime(note.updatedAt),
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
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
                      color: isSelected ? theme.colorScheme.onSurface : Colors.black26,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: theme.colorScheme.surface, size: 14)
                        : null,
                  ),
                )
              else if (note.isPinned)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Icon(Icons.push_pin, color: theme.primaryColor, size: 16),
                ),
            ],
          ),
        ),
      );
    });
  }

  String _formatTime(DateTime? date) {
    if (date == null) return "";
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('MMM d').format(date); 
  }

  String _getContentSnippet(NoteModel note) {
    if (note.content.isEmpty) return "No additional text";
    final firstBlock = note.content.firstWhereOrNull((b) => b is TextBlock) as TextBlock?;
    return firstBlock != null ? firstBlock.text : "Attachment/Checklist";
  }
}

class _GridImage extends StatelessWidget {
  final AttachmentBlock attachment;

  const _GridImage({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = attachment.url;
    final localPath = attachment.localPath;

    if (localPath != null && File(localPath).existsSync()) {
      return Image.file(
        File(localPath),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _GridPlaceholder(),
      );
    }

    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
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
                color: theme.primaryColor,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _GridPlaceholder(),
      );
    }

    return _GridPlaceholder();
  }
}

class _GridPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
      child: Icon(
        CupertinoIcons.photo,
        size: 30,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }
}
