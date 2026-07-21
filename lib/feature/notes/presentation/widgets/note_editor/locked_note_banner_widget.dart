part of '../../view/note_editor_view.dart';

class _LockedNoteBanner extends StatelessWidget {
  const _LockedNoteBanner();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final ColorScheme colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: <Widget>[
          Icon(CupertinoIcons.lock_fill, size: 20, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This note is locked. Unlock it from '
              'Note Options to make changes.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
