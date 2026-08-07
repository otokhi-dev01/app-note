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
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          image: DecorationImage(
                            image: attachment.url != null 
                              ? NetworkImage(attachment.url!) 
                              : const AssetImage('assets/images/placeholder.png') as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
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
                const Positioned(
                  top: 8,
                  left: 8,
                  child: Icon(Icons.push_pin, color: AppTheme.folderYellow, size: 16),
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
