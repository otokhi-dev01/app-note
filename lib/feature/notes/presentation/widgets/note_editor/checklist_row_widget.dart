part of '../../view/note_editor_view.dart';

class _ChecklistRow extends StatelessWidget {
  final NoteChecklistBlockDraft block;
  final NoteChecklistItemDraft item;
  final bool canEdit;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  const _ChecklistRow({
    super.key,
    required this.block,
    required this.item,
    required this.canEdit,
    required this.onToggle,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Checkbox.adaptive(
            value: item.checked,
            activeColor: colors.primary,
            onChanged: canEdit
                ? (bool? value) {
                    onToggle(value ?? false);
                  }
                : null,
          ),
          Expanded(
            child: TextFormField(
              initialValue: item.text,
              readOnly: !canEdit,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Task',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: item.checked
                    ? colors.onSurfaceVariant
                    : colors.onSurface,
                decoration: item.checked ? TextDecoration.lineThrough : null,
              ),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 34,
            height: 34,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              pressedOpacity: 0.45,
              onPressed: canEdit ? onRemove : null,
              child: Icon(
                CupertinoIcons.xmark_circle,
                size: 19,
                color: canEdit
                    ? colors.onSurfaceVariant
                    : colors.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
