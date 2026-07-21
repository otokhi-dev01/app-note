part of '../../view/note_editor_view.dart';

class _ChecklistCard extends StatelessWidget {
  final NoteEditorController controller;

  const _ChecklistCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final ColorScheme colors = theme.colorScheme;

    final List<NoteChecklistBlockDraft> blocks = controller.checklistBlocks;

    final List<({NoteChecklistBlockDraft block, NoteChecklistItemDraft item})>
    rows = <({NoteChecklistBlockDraft block, NoteChecklistItemDraft item})>[
      for (final NoteChecklistBlockDraft block in blocks)
        for (final NoteChecklistItemDraft item in block.items)
          (block: block, item: item),
    ];

    final int completed = rows.where((row) => row.item.checked).length;

    return AppSurfaceCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          _SectionTitleRow(
            icon: CupertinoIcons.checkmark_square_fill,
            title: 'Checklist',
            subtitle: rows.isEmpty
                ? 'Add tasks to this note'
                : '$completed of ${rows.length} completed',
            actionIcon: CupertinoIcons.add_circled_solid,
            actionTooltip: 'Add task',
            actionEnabled: controller.canEdit,
            onAction: controller.addChecklistItem,
          ),

          if (rows.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),

            Divider(
              height: 1,
              color: colors.outlineVariant.withValues(alpha: 0.45),
            ),

            const SizedBox(height: 7),

            for (final row in rows)
              _ChecklistRow(
                key: ValueKey<String>(row.item.id),
                block: row.block,
                item: row.item,
                canEdit: controller.canEdit,
                onToggle: (bool value) {
                  controller.toggleChecklistItem(
                    row.block.id,
                    row.item.id,
                    value,
                  );
                },
                onChanged: (String value) {
                  controller.updateChecklistItem(
                    row.block.id,
                    row.item.id,
                    value,
                  );
                },
                onRemove: () {
                  controller.removeChecklistItem(row.block.id, row.item.id);
                },
              ),
          ],
        ],
      ),
    );
  }
}
