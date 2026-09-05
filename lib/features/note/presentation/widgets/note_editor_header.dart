import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/folder/presentation/widgets/folder_breadcrumb.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';

class NoteEditorHeader extends StatelessWidget {
  final NoteDetailController controller;

  const NoteEditorHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant.withValues(alpha: 0.68);

    return Obx(() {
      final note = controller.currentNote.value;
      final date = note?.updatedAt ?? DateTime.now();
      final folder = controller.resolveFolder(note?.folderId ?? 0);
      final folderPath = controller.resolveFolderPath(note?.folderId ?? 0);
      final isSaving = controller.isSaving.value;
      final canChangeFolder =
          note != null &&
          !controller.isReadOnly.value &&
          !controller.isLoading.value &&
          !isSaving;

      return ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller.titleController,
        builder: (context, _, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _FolderButton(
              folder: folder,
              folderPath: folderPath,
              fallbackFolderLabel: controller.resolveFolderLabel(),
              noteTitle: controller.titleController.text.trim().isEmpty
                  ? 'note_editor_untitled_note'.tr
                  : controller.titleController.text.trim(),
              label: controller.resolveNoteBreadcrumb(),
              enabled: canChangeFolder,
              onPressed: () {
                unawaited(HapticFeedback.selectionClick());
                unawaited(controller.moveNote());
              },
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: isSaving
                  ? _SavingStatus(key: const ValueKey('saving'), color: muted)
                  : _DateStatus(
                      key: const ValueKey('date'),
                      date: date,
                      color: muted,
                    ),
            ),
          ],
        ),
      );
    });
  }
}

class _FolderButton extends StatelessWidget {
  final Folder? folder;
  final List<Folder> folderPath;
  final String fallbackFolderLabel;
  final String noteTitle;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _FolderButton({
    required this.folder,
    required this.folderPath,
    required this.fallbackFolderLabel,
    required this.noteTitle,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final content = FolderBreadcrumb(
      key: const ValueKey('note-folder-breadcrumb'),
      pathKey: const ValueKey('note-folder-path'),
      folder: folder,
      folderPath: folderPath,
      fallbackFolderLabel: fallbackFolderLabel,
      noteTitle: noteTitle,
      semanticLabel: label,
      showDisclosure: enabled,
    );
    if (!enabled) return content;
    return Semantics(
      button: true,
      label: '${'note_editor_change_folder_label'.tr}: $label',
      child: Tooltip(
        message: 'note_editor_change_folder_label'.tr,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _DateStatus extends StatelessWidget {
  final DateTime date;
  final Color color;
  const _DateStatus({super.key, required this.date, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(CupertinoIcons.clock, size: 12, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            DateFormat("MMMM d, yyyy 'at' h:mm a").format(date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _SavingStatus extends StatelessWidget {
  final Color color;
  const _SavingStatus({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoActivityIndicator(radius: 7, color: color),
        const SizedBox(width: 7),
        Text(
          'note_editor_saving_indicator'.tr.replaceFirst('·', '').trim(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
