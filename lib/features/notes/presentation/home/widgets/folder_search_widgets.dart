part of '../home_view.dart';

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.title,
    required this.icon,
    required this.count,
    required this.onTap,
    required this.showEdit,
    this.isLast = false,
  });

  final String title;
  final IconData icon;
  final int count;
  final VoidCallback onTap;
  final bool showEdit;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 2,
          ),
          leading: Icon(icon, color: AppColors.primary, size: 27),
          title: Text(title, style: const TextStyle(fontSize: 17)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showEdit)
                const Icon(
                  CupertinoIcons.pencil_circle,
                  color: AppColors.primary,
                )
              else ...[
                Text(
                  '$count',
                  style: const TextStyle(
                    color: AppColors.subtitle,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: AppColors.outline,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.only(left: 64),
            child: Divider(height: 1),
          ),
      ],
    );
  }
}

class _RestoreFolderRow extends StatelessWidget {
  const _RestoreFolderRow({
    required this.folder,
    required this.isLast,
    required this.onRestore,
  });

  final Folder folder;
  final bool isLast;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(
            CupertinoIcons.folder_badge_minus,
            color: AppColors.primary,
          ),
          title: Text(
            folder.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: const Text('Deleted from your synced folders'),
          trailing: TextButton(
            onPressed: onRestore,
            child: const Text('Restore'),
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 60),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.label,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 150,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.subtitle,
                  fontSize: 12,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(icon, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaTypeCard extends StatelessWidget {
  const _MediaTypeCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 26),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSearchRow extends StatelessWidget {
  const _RecentSearchRow({
    required this.value,
    required this.isLast,
    required this.onTap,
  });

  final String value;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: const Icon(CupertinoIcons.time, size: 20),
          title: Text(value),
          trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
        ),
        if (!isLast) const Divider(height: 1, indent: 52),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            width: 120,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
