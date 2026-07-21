part of 'home_header_widget.dart';

class _HeaderContent extends StatelessWidget {
  final String title;
  final int noteCount;
  final bool isLoading;
  final VoidCallback onOpenFolders;
  final VoidCallback onRefresh;
  final VoidCallback onOpenMenu;

  const _HeaderContent({
    required this.title,
    required this.noteCount,
    required this.isLoading,
    required this.onOpenFolders,
    required this.onRefresh,
    required this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpenFolders,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$noteCount '
                  '${noteCount == 1 ? 'note' : 'notes'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            ),
          )
        else
          _GlassIconButton(icon: Icons.refresh_rounded, onPressed: onRefresh),

        const SizedBox(width: 4),

        _GlassIconButton(icon: Icons.more_horiz_rounded, onPressed: onOpenMenu),
      ],
    );
  }
}
