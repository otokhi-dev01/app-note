import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:Note/core/utils/media_title.dart';

class NoteMediaTitle extends StatelessWidget {
  final String displayName;
  final String fallbackTitle;
  final String? fixedTitle;
  final bool isReadOnly;
  final ValueChanged<String> onChanged;

  const NoteMediaTitle({
    super.key,
    required this.displayName,
    required this.fallbackTitle,
    this.fixedTitle,
    required this.isReadOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tileColor = CupertinoDynamicColor.resolve(
      CupertinoColors.systemGrey5,
      context,
    );
    final title =
        fixedTitle ??
        mediaTitleFromDisplayName(displayName, fallback: fallbackTitle);
    final canEdit = !isReadOnly && fixedTitle == null;

    return Semantics(
      button: canEdit,
      label: title,
      hint: canEdit ? 'note_editor_edit_media_title'.tr : null,
      child: InkWell(
        key: ValueKey('media-title-$displayName'),
        onTap: canEdit ? () => _showEditor(context, title) : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (canEdit) ...[
                const SizedBox(width: 6),
                Icon(
                  CupertinoIcons.pencil,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditor(BuildContext context, String title) async {
    final textController = TextEditingController(text: title);
    textController.selection = TextSelection.collapsed(offset: title.length);

    final updatedTitle = await showCupertinoDialog<String>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text('note_editor_edit_media_title'.tr),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            key: const ValueKey('media-title-field'),
            controller: textController,
            autofocus: true,
            maxLength: 120,
            placeholder: 'note_editor_media_title_hint'.tr,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.pop(dialogContext, value.trim());
              }
            },
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final value = textController.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: Text('save_action'.tr),
          ),
        ],
      ),
    );

    textController.dispose();
    if (updatedTitle != null && updatedTitle != title) onChanged(updatedTitle);
  }
}
