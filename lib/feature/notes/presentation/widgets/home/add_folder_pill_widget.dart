part of 'home_folder_strip_widget.dart';

class _AddFolderPill extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _AddFolderPill({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: isLoading ? null : onTap,
      child: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surface.withValues(alpha: 0.62),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.34),
          ),
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
              )
            : Icon(Icons.add_rounded, color: colorScheme.primary),
      ),
    );
  }
}
