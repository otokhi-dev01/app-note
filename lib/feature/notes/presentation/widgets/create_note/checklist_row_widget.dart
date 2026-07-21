part of '../../view/create_note_view.dart';

class _ChecklistRow extends StatelessWidget {
  final CreateNoteChecklistItem item;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  const _ChecklistRow({
    super.key,
    required this.item,
    required this.enabled,
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
            onChanged: enabled
                ? (bool? value) {
                    onToggle(value ?? false);
                  }
                : null,
          ),
          Expanded(
            child: TextFormField(
              initialValue: item.text,
              enabled: enabled,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Task',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
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
              onPressed: enabled ? onRemove : null,
              child: Icon(
                CupertinoIcons.xmark_circle,
                size: 19,
                color: enabled
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
