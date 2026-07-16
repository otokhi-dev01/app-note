part of '../home_view.dart';

void _handleNoteAction(String action, Note note, HomeController controller) {
  switch (action) {
    case 'pin':
      controller.togglePin(note);
    case 'share':
      controller.shareNote(note);
    case 'move':
      controller.moveNote(note);
    case 'delete':
      controller.deleteNote(note);
  }
}

void _showFolderActions(
  BuildContext context,
  HomeController controller,
  Folder folder,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.pencil),
              title: const Text('Rename Folder'),
              onTap: () {
                Navigator.pop(context);
                controller.renameFolder(folder);
              },
            ),
            ListTile(
              leading: Icon(
                CupertinoIcons.trash,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete Folder',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                controller.deleteFolder(folder);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

void _showDeletedActions(
  BuildContext context,
  HomeController controller,
  Note note,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                CupertinoIcons.arrow_counterclockwise,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Recover Note'),
              onTap: () {
                Navigator.pop(context);
                controller.restoreNote(note);
              },
            ),
            ListTile(
              leading: Icon(
                CupertinoIcons.trash,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete Permanently',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                controller.permanentlyDeleteNote(note);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

void _showAppMenu(BuildContext context, HomeController controller) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Library Tools',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _MenuTile(
              icon: CupertinoIcons.photo_on_rectangle,
              title: 'Media Gallery',
              onTap: () => _openMenuRoute(context, AppRoutes.media),
            ),
            _MenuTile(
              icon: CupertinoIcons.tag,
              title: 'Tags Manager',
              onTap: () => _openMenuRoute(context, AppRoutes.tags),
            ),
            _MenuTile(
              icon: CupertinoIcons.calendar,
              title: 'Note Calendar',
              onTap: () => _openMenuRoute(context, AppRoutes.calendar),
            ),
            _MenuTile(
              icon: CupertinoIcons.sparkles,
              title: 'Smart Categories',
              onTap: () => _openMenuRoute(context, AppRoutes.categories),
            ),
            _MenuTile(
              icon: CupertinoIcons.time,
              title: 'Recent Activity',
              onTap: () => _openMenuRoute(context, AppRoutes.history),
            ),
            _MenuTile(
              icon: CupertinoIcons.cloud,
              title: 'Storage Management',
              onTap: () => _openMenuRoute(context, AppRoutes.storage),
            ),
            _MenuTile(
              icon: CupertinoIcons.settings,
              title: 'Settings',
              onTap: () => _openMenuRoute(context, AppRoutes.settings),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 21,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: Icon(
        CupertinoIcons.chevron_right,
        size: 15,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

void _openMenuRoute(BuildContext context, String route) {
  Navigator.pop(context);
  Get.toNamed(route);
}
