part of 'folder_list_view.dart';

class _GlassSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _GlassSearchField({
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: CupertinoSearchTextField(
        controller: controller,
        placeholder: 'Search folders...',
        borderRadius: BorderRadius.circular(14),
        backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colors.onSurface,
          letterSpacing: -0.2,
        ),
        placeholderStyle: theme.textTheme.bodyLarge?.copyWith(
          color: colors.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        itemColor: colors.onSurfaceVariant,
        itemSize: 20,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onChanged: onChanged,
        onSuffixTap: onClear,
      ),
    );
  }
}
