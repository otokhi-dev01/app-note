part of '../../view/note_list_view.dart';

class _NoteRow extends StatelessWidget {
  final NoteEntity note;
  final String folderName;
  final Color folderColor;
  final VoidCallback onTap;
  final VoidCallback onMore;

  const _NoteRow({
    required this.note,
    required this.folderName,
    required this.folderColor,
    required this.onTap,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final ColorScheme colors = theme.colorScheme;

    final bool isDark = theme.brightness == Brightness.dark;

    final Color cardColor = isDark ? const Color(0xFF1B1D22) : Colors.white;

    final String title = note.title.trim().isEmpty
        ? 'Untitled Note'
        : note.title.trim();

    final DateTime? timestamp = note.updatedAt ?? note.createdAt;

    final int attachmentCount = _attachmentCount(note);

    final Color borderColor = note.isPinned
        ? colors.primary.withValues(alpha: isDark ? 0.40 : 0.28)
        : colors.outlineVariant.withValues(alpha: isDark ? 0.18 : 0.35);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onMore,
        borderRadius: BorderRadius.circular(20),
        splashColor: colors.primary.withValues(alpha: 0.08),
        highlightColor: colors.primary.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: note.isPinned ? 1.2 : 1,
            ),
            boxShadow: isDark
                ? const <BoxShadow>[]
                : <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.035),
                      blurRadius: 16,
                      spreadRadius: -8,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _NoteIcon(color: folderColor, locked: note.isLocked),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (note.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(left: 7),
                            child: Icon(
                              CupertinoIcons.pin_fill,
                              size: 14,
                              color: colors.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _notePreview(note),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _NoteMetadata(
                      folderName: folderName,
                      folderColor: folderColor,
                      locked: note.isLocked,
                      attachmentCount: attachmentCount,
                      timestamp: timestamp,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 38,
                height: 38,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  pressedOpacity: 0.45,
                  onPressed: onMore,
                  child: Icon(
                    CupertinoIcons.ellipsis_circle,
                    size: 21,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
