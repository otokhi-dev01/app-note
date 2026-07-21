part of '../../view/note_list_view.dart';

class _NoteSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _NoteSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final ColorScheme colors = theme.colorScheme;

    final bool isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: CupertinoSearchTextField(
        controller: controller,
        placeholder: 'Search notes',
        borderRadius: BorderRadius.circular(15),
        backgroundColor: colors.onSurface.withValues(
          alpha: isDark ? 0.07 : 0.055,
        ),
        style: TextStyle(color: colors.onSurface),
        placeholderStyle: TextStyle(color: colors.onSurfaceVariant),
        itemColor: colors.onSurfaceVariant,
        onChanged: onChanged,
        onSuffixTap: onClear,
      ),
    );
  }
}
