import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/note_model.dart';
import '../../../routes/note_navigation.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/ios_action_menu.dart';
import '../../../widgets/ios_confirmation_dialog.dart';
import '../controllers/note_controller.dart';

class NoteListTile extends StatelessWidget {
  final NoteModel note;
  final int folderId;
  final NoteController controller;

  const NoteListTile({
    super.key,
    required this.note,
    required this.folderId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attachment =
        note.content.firstWhereOrNull((b) => b is AttachmentBlock)
            as AttachmentBlock?;

    return Obx(() {
      final isEditing = controller.isEditing.value;
      final isSelected = controller.selectedNoteIds.contains(note.id);

      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        onLongPress: isEditing ? null : () => _showContextMenu(context), // Logic: Hold to show delete popup
        leading: isEditing
            ? _buildSelectionIndicator(theme, isSelected)
            : (note.isPinned
                  ? const Icon(
                      Icons.push_pin,
                      color: AppTheme.folderPink,
                      size: 16,
                    )
                  : null),
        title: Text(
          note.displayTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            "${_formatTime(note.updatedAt)}  ${_getContentSnippet(note)}",
            style: theme.textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: attachment != null
            ? _buildAttachmentThumbnail(attachment)
            : (isEditing
                  ? null
                  : Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.outline,
                      size: 20,
                    )),
      );
    });
  }

  void _showContextMenu(BuildContext context) {
    Get.dialog(
      IOSActionMenu(
        type: IOSMenuType.popup,
        title: "Note Options",
        actions: [
          IOSMenuAction(
            label: note.isPinned ? "Unpin Note" : "Pin Note",
            icon: note.isPinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
            onTap: () async {
              Get.back();
              await controller.updateNoteState(note.id, isPinned: !note.isPinned);
              await controller.fetchNotes(folderId: folderId, refresh: true);
            },
          ),
          IOSMenuAction(
            label: "Move Note",
            icon: CupertinoIcons.folder_badge_plus,
            onTap: () {
              Get.back();
              controller.selectedNoteIds.clear();
              controller.selectedNoteIds.add(note.id);
              controller.moveSelectedNotes(context, folderId);
            },
          ),
          IOSMenuAction(
            label: "Delete",
            icon: CupertinoIcons.trash,
            isDestructive: true,
            onTap: () {
              Get.back(); // Close menu
              // FEATURE: Confirmation before deleting from list popup
              Get.dialog(
                IOSConfirmationDialog(
                  title: "Are you sure you want to move this note to Recently Deleted?",
                  confirmLabel: "Delete Note",
                  onConfirm: () async {
                    // Set selection to just this note to use existing controller logic safely
                    controller.selectedNoteIds.clear();
                    controller.selectedNoteIds.add(note.id);
                    await controller.deleteSelectedNotes(folderId);
                  },
                ),
              );
            },
          ),
        ],
      ),
      barrierColor: Colors.black.withValues(alpha: 0.1),
    );
  }

  Widget _buildSelectionIndicator(ThemeData theme, bool isSelected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? theme.colorScheme.onSurface : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: isSelected
          ? Icon(Icons.check, color: theme.colorScheme.surface, size: 14)
          : null,
    );
  }

  Widget _buildAttachmentThumbnail(AttachmentBlock attachment) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: attachment.url != null
              ? NetworkImage(attachment.url!)
              : const AssetImage('assets/images/placeholder.png')
                    as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  String _formatTime(DateTime? date) {
    if (date == null) return "";
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('EEEE').format(date);
  }

  String _getContentSnippet(NoteModel note) {
    if (note.content.isEmpty) {
      if (note.attachmentCount > 0)
        return "${note.attachmentCount} attachment${note.attachmentCount > 1 ? 's' : ''}";
      return "No additional text";
    }
    final firstBlock =
        note.content.firstWhereOrNull((b) => b is TextBlock) as TextBlock?;
    if (firstBlock == null) return "Attachment/Checklist";

    return NoteModel.extractPlainText(firstBlock.text);
  }
}
