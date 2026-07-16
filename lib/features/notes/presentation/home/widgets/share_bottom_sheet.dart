part of 'home_sheets.dart';

class ShareBottomSheet extends StatelessWidget {
  const ShareBottomSheet({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: style.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: style.placeholder,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Share Note',
            style: style.theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          _ShareOption(
            icon: CupertinoIcons.doc_on_doc,
            label: 'Copy to Clipboard',
            onTap: () async {
              final text = note.title.trim().isEmpty
                  ? note.content
                  : '${note.title}\n\n${note.content}';
              await Clipboard.setData(ClipboardData(text: text));
              Get.back();
              Get.snackbar('Copied', 'Note content copied to clipboard.');
            },
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: style.secondarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: HomeStyle.blue, size: 22),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        trailing: Icon(
          CupertinoIcons.chevron_right,
          size: 14,
          color: style.placeholder,
        ),
      ),
    );
  }
}
