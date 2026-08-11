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
                      "Add Item",
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
              ? 'Mark checklist item incomplete'
              : 'Mark checklist item complete',
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
          child: TextField(
            key: ValueKey('checklist-${block.id}-${item.id}'),
            controller: controller.getTextController(
              '${block.id}_${item.id}',
              item.text,
            ),
            enabled: !controller.isReadOnly.value,
            onChanged: (value) =>
                controller.onUpdateChecklistItem(blockIndex, itemIndex, value),
            cursorColor: theme.primaryColor,
            cursorWidth: 1.5,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.45,
              decoration: item.checked ? TextDecoration.lineThrough : null,
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
