part of 'home_sheets.dart';

class ShareBottomSheet extends StatelessWidget {
  const ShareBottomSheet({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);
    final scheme = style.theme.colorScheme;
    final noteTitle = note.title.trim().isEmpty ? 'Untitled Note' : note.title;
    final notePreview = note.content.trim().isEmpty
        ? 'No additional text'
        : note.content;

    return _NotesSheet(
      maxHeightFactor: 0.68,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(
            title: 'Share Note',
            subtitle: 'Send a clean text copy of this note.',
            trailing: _SheetIconButton(
              icon: CupertinoIcons.xmark,
              tooltip: 'Close share options',
              onPressed: () => Get.back(),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SheetSectionLabel('Note'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            CupertinoIcons.doc_text_fill,
                            color: scheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                noteTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: style.theme.textTheme.titleMedium
                                    ?.copyWith(
                                      color: scheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notePreview,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: style.theme.textTheme.bodyMedium
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.3,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _SheetSectionLabel('Actions'),
                  _ShareOption(
                    icon: CupertinoIcons.doc_on_doc_fill,
                    label: 'Copy Note',
                    subtitle: 'Copy the title and text to the clipboard',
                    onTap: () async {
                      final text = note.title.trim().isEmpty
                          ? note.content
                          : '${note.title}\n\n${note.content}';
                      await Clipboard.setData(ClipboardData(text: text));
                      Get.back();
                      Get.snackbar(
                        'Copied',
                        'Note content copied to clipboard.',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);
    final scheme = style.theme.colorScheme;

    return Semantics(
      button: true,
      label: label,
      hint: subtitle,
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 70),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: scheme.onPrimary, size: 20),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: style.theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style.theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 15,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
