import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';

class NoteTableBlock extends StatelessWidget {
  final TableBlock block;
  final int blockIndex;
  final NoteDetailController controller;

  const NoteTableBlock({
    super.key,
    required this.block,
    required this.blockIndex,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor, width: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Table(
              border: TableBorder.all(color: theme.dividerColor, width: 0.5),
              children: [
                for (int r = 0; r < block.rows.length; r++)
                  TableRow(
                    children: [
                      for (int c = 0; c < block.rows[r].length; c++)
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: TextField(
                            controller: controller.getTextController(
                              'table_${block.id}_${r}_$c',
                              block.rows[r][c],
                            ),
                            enabled: !controller.isReadOnly.value,
                            onChanged: (value) => controller.updateTableCell(
                              blockIndex,
                              r,
                              c,
                              value,
                            ),
                            style: theme.textTheme.bodyMedium,
                            maxLines: null,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.all(8),
                              filled: false,
                              fillColor:
                                  Colors.transparent, // Explicitly transparent
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          if (!controller.isReadOnly.value)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  _TableActionButton(
                    icon: CupertinoIcons.add,
                    label: 'Row',
                    onTap: () => controller.addTableRow(blockIndex),
                  ),
                  const SizedBox(width: 12),
                  _TableActionButton(
                    icon: CupertinoIcons.add,
                    label: 'Column',
                    onTap: () => controller.addTableColumn(blockIndex),
                  ),
                  const Spacer(),
                  _TableActionButton(
                    icon: CupertinoIcons.trash,
                    label: 'Delete',
                    color: Colors.redAccent.withValues(alpha: 0.8),
                    onTap: () => controller.deleteBlock(blockIndex),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TableActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _TableActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: effectiveColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: effectiveColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
