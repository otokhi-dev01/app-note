import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final folderColor = folder?.color ?? scheme.primary;

    final content = Container(
      key: const ValueKey('note-folder-breadcrumb'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: folderColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: folderColor.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (folderPath.isEmpty) ...[
                    _folderIcon(folder, folderColor),
                    TextSpan(text: ' $fallbackFolderLabel'),
                  ] else
                    for (var index = 0; index < folderPath.length; index++) ...[
                      if (index > 0) const TextSpan(text: ' › '),
                      _folderIcon(folderPath[index], folderPath[index].color),
                      TextSpan(text: ' ${folderPath[index].displayName}'),
                    ],
                  TextSpan(text: ' › $noteTitle'),
                ],
              ),
              key: const ValueKey('note-folder-path'),
              semanticsLabel: label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (enabled) ...[
            const SizedBox(width: 5),
            Icon(
              CupertinoIcons.chevron_down,
              size: 11,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
            ),
          ],
        ],
      ),
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

  WidgetSpan _folderIcon(Folder? folder, Color color) => WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: ExcludeSemantics(
      child: folder != null
          ? FolderGlyph(
              key: ValueKey('note-folder-icon-${folder.id}'),
              folder: folder,
              size: 14,
            )
          : Icon(
              FolderAppearance.iconFor(FolderAppearance.defaultIconName),
              size: 14,
              color: color,
            ),
    ),
  );
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
