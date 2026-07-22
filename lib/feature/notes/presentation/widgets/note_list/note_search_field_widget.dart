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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: AppGlassSurface(
        borderRadius: 30,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        tintColor: colors.surface.withValues(alpha: isDark ? 0.65 : 0.55),
        child: CupertinoSearchTextField(
          controller: controller,
          placeholder: 'Search notes...',
          borderRadius: BorderRadius.circular(30),
          backgroundColor: Colors.transparent,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurface,
            letterSpacing: -0.2,
          ),
          placeholderStyle: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          itemColor: colors.onSurfaceVariant,
          itemSize: 20,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          onChanged: onChanged,
          onSuffixTap: onClear,
        ),
      ),
    );
  }
}
