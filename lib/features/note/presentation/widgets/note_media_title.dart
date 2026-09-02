import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:Note/core/utils/media_title.dart';

class NoteMediaTitle extends StatelessWidget {
  final String displayName;
  final String fallbackTitle;
  final bool isReadOnly;
  final ValueChanged<String> onChanged;

  const NoteMediaTitle({
    super.key,
    required this.displayName,
    required this.fallbackTitle,
    required this.isReadOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = mediaTitleFromDisplayName(
      displayName,
      fallback: fallbackTitle,
    );

    return Semantics(
      button: !isReadOnly,
      label: title,
      hint: isReadOnly ? null : 'note_editor_edit_media_title'.tr,
      child: InkWell(
        key: ValueKey('media-title-$displayName'),
        onTap: isReadOnly ? null : () => _showEditor(context, title),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
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
              if (!isReadOnly) ...[
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
