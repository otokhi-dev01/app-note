import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/features/note/presentation/widgets/note_scroll_utils.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';

class NoteChecklistBlock extends StatelessWidget {
  final ChecklistBlock block;
  final int blockIndex;
  final NoteDetailController controller;

  const NoteChecklistBlock({
    super.key,
    required this.block,
    required this.blockIndex,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          for (int i = 0; i < block.items.length; i++)
            _buildChecklistItem(context, block.items[i], i),
          if (!controller.isReadOnly.value)
            Padding(
              padding: const EdgeInsets.only(left: 31, top: 4),
              child: InkWell(
                onTap: () => controller.addChecklistItem(blockIndex),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.add,
                      size: 18,
                      color: AppTheme.folderPink,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'note_editor_add_item'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(
    BuildContext context,
    ChecklistItem item,
    int itemIndex,
  ) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          checked: item.checked,
          label: item.checked
              ? 'note_editor_mark_item_incomplete'.tr
              : 'note_editor_mark_item_complete'.tr,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => controller.toggleChecklistItem(blockIndex, itemIndex),
            child: SizedBox(
              width: 31,
              height: 31,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  item.checked
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.circle,
                  color: item.checked
                      ? theme.primaryColor
                      : theme.colorScheme.onSurfaceVariant,
                  size: 21,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Builder(
            builder: (itemContext) {
              final fieldKey = '${block.id}_${item.id}';
              final textController = controller.getTextController(
                fieldKey,
                item.text,
              );
              // Prime a truly-empty item with the invisible placeholder so a
              // later Backspace-at-start has something to delete — see
              // kChecklistItemPlaceholder for why this is necessary.
              if (textController.text.isEmpty) {
                textController.value = TextEditingValue(
                  text: kChecklistItemPlaceholder,
                  selection: TextSelection.collapsed(
                    offset: kChecklistItemPlaceholder.length,
                  ),
                );
              }

              return Focus(
                onFocusChange: (hasFocus) {
                  if (hasFocus) ensureBlockVisible(itemContext);
                },
                child: TextField(
                  key: ValueKey('checklist-${block.id}-${item.id}'),
                  controller: textController,
                  focusNode: controller.getBlockFocusNode(fieldKey),
                  enabled: !controller.isReadOnly.value,
                  onChanged: (value) => controller.onUpdateChecklistItem(
                    blockIndex,
                    itemIndex,
                    value.startsWith(kChecklistItemPlaceholder)
                        ? value.substring(kChecklistItemPlaceholder.length)
                        : value,
                  ),
                  // iOS Notes never inserts a literal newline into a
                  // checklist item — Return always starts a new item (or
                  // exits the list on an empty one) instead. Backspace at
                  // the start of an empty item deletes it and merges into
                  // the item above, same as iOS Notes.
                  inputFormatters: [
                    _ChecklistTextFormatter(
                      onEnter: () => controller.onChecklistItemEnter(
                        blockIndex,
                        itemIndex,
                      ),
                      onBackspaceAtStart: () => controller
                          .onChecklistItemBackspace(blockIndex, itemIndex),
                    ),
                  ],
                  cursorColor: theme.primaryColor,
                  cursorWidth: 1.5,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.45,
                    decoration: item.checked
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: theme.colorScheme.onSurfaceVariant,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isCollapsed: true,
                    filled: false,
                    fillColor: Colors.transparent,
                  ),
                ),
              );
            },
          ),
        ),
        if (!controller.isReadOnly.value && block.items.length > 1)
          IconButton(
            icon: const Icon(CupertinoIcons.xmark, size: 16),
            onPressed: () =>
                controller.deleteChecklistItem(blockIndex, itemIndex),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

/// Intercepts a Return keypress on a multiline [TextField] before the
/// newline is ever inserted, calling [onEnter] and keeping the field's text
/// unchanged instead. Also watches for the item's placeholder character
/// (see [kChecklistItemPlaceholder]) being deleted, which is what an
/// otherwise-invisible Backspace-on-empty-item press looks like once it
/// reaches a formatter, and reports that as [onBackspaceAtStart].
class _ChecklistTextFormatter extends TextInputFormatter {
  final VoidCallback onEnter;
  final VoidCallback onBackspaceAtStart;

  _ChecklistTextFormatter({
    required this.onEnter,
    required this.onBackspaceAtStart,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.contains('\n')) {
      onEnter();
      return oldValue;
    }
    if (oldValue.text == kChecklistItemPlaceholder && newValue.text.isEmpty) {
      onBackspaceAtStart();
      return newValue;
    }
    return newValue;
  }
}
