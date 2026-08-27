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
      final folderName = controller.resolveFolderLabel();
      final isSaving = controller.isSaving.value;
      final canChangeFolder =
          note != null &&
          !controller.isReadOnly.value &&
          !controller.isLoading.value &&
          !isSaving;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (folderName.isNotEmpty)
            _FolderButton(
              folder: folder,
              label: folderName,
              enabled: canChangeFolder,
              onPressed: () {
                unawaited(HapticFeedback.selectionClick());
                unawaited(controller.moveNote());
              },
            ),
          if (folderName.isNotEmpty) const SizedBox(height: 8),
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
      );
    });
  }
}

class _FolderButton extends StatelessWidget {
  final Folder? folder;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _FolderButton({
    required this.folder,
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
      constraints: const BoxConstraints(maxWidth: 280, minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: folderColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: folderColor.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (folder != null)
            FolderGlyph(folder: folder!, size: 14)
          else
            Icon(
              FolderAppearance.iconFor(FolderAppearance.defaultIconName),
              size: 14,
              color: folderColor,
            ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
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
        Text(
          DateFormat("MMMM d, yyyy 'at' h:mm a").format(date),
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontSize: 12.5,
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
