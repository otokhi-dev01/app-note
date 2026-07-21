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
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: _GlassSurface(
        borderRadius: 18,
        padding: EdgeInsets.zero,
        child: CupertinoSearchTextField(
          controller: controller,
          placeholder: 'Search folders',
          borderRadius: BorderRadius.circular(18),
          backgroundColor: Colors.transparent,
          style: TextStyle(color: colors.onSurface),
          placeholderStyle: TextStyle(color: colors.onSurfaceVariant),
          itemColor: colors.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          onChanged: onChanged,
          onSuffixTap: onClear,
        ),
      ),
    );
  }
}
