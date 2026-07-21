part of '../../view/create_note_view.dart';

class _ChecklistSection extends GetView<CreateNoteController> {
  const _ChecklistSection();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Obx(() {
      final List<CreateNoteChecklistItem> items =
          List<CreateNoteChecklistItem>.unmodifiable(
            controller.checklistItems.toList(),
          );

      if (items.isEmpty) {
        return const SizedBox.shrink();
      }

      final int completed = items.where((CreateNoteChecklistItem item) {
        return item.checked;
      }).length;

      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: AppSurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              _SectionHeader(
                icon: CupertinoIcons.checkmark_square_fill,
                title: 'Checklist',
                subtitle: '$completed of ${items.length} completed',
                onAdd: controller.isSaving.value
                    ? null
                    : controller.addChecklistItem,
              ),

              const SizedBox(height: 12),

              Divider(
                height: 1,
                color: colors.outlineVariant.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.18 : 0.35,
                ),
              ),

              const SizedBox(height: 6),

              for (final CreateNoteChecklistItem item in items)
                _ChecklistRow(
                  key: ValueKey<String>(item.id),
                  item: item,
                  enabled: !controller.isSaving.value,
                  onToggle: (bool value) {
                    controller.toggleChecklistItem(item.id, value);
                  },
                  onChanged: (String value) {
                    controller.updateChecklistItem(item.id, value);
                  },
                  onRemove: () {
                    controller.removeChecklistItem(item.id);
                  },
                ),
            ],
          ),
        ),
      );
    });
  }
}
