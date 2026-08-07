import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../data/models/note_model.dart';
import '../../../theme/app_theme.dart';
import '../controllers/note_detail_controller.dart';

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
          for (final entry in block.items.asMap().entries)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  button: true,
                  checked: entry.value.checked,
                  label: entry.value.checked
                      ? 'Mark checklist item incomplete'
                      : 'Mark checklist item complete',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => controller.toggleChecklistItem(
                      blockIndex,
                      entry.key,
                    ),
                    child: SizedBox(
                      width: 31,
                      height: 31,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(
                          entry.value.checked
                              ? CupertinoIcons.check_mark_circled_solid
                              : CupertinoIcons.circle,
                          color: entry.value.checked
                              ? AppTheme.folderYellow
                              : theme.colorScheme.onSurfaceVariant,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    key: ValueKey(
                      'checklist-${block.id}-${entry.value.id}',
                    ),
                    controller: controller.getTextController(
                      '${block.id}_${entry.value.id}',
                      entry.value.text,
                    ),
                    enabled: !controller.isReadOnly.value,
                    onChanged: (value) => controller.onUpdateChecklistItem(
                      blockIndex,
                      entry.key,
                      value,
                    ),
                    cursorColor: AppTheme.folderYellow,
                    cursorWidth: 1.5,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    scrollPadding: const EdgeInsets.only(bottom: 92),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.45,
                      decoration: entry.value.checked
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
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
