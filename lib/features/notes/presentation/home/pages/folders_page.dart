part of '../home_view.dart';

class _FoldersPage extends StatelessWidget {
  const _FoldersPage({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      bottom: false,
      child: Obx(() {
        return RefreshIndicator(
          onRefresh: controller.loadNotes,
          color: scheme.primary,
          child: ListView(
            key: const PageStorageKey('folders_page'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              if (controller.isFolderSyncing.value)
                LinearProgressIndicator(minHeight: 2, color: scheme.primary),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
                child: _SearchField(
                  hint: 'Search folders and notes',
                  readOnly: true,
                  onTap: () => controller.selectTab(2),
                ),
              ),
              const _SectionLabel('On My Device'),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: _SurfaceCard(
                  child: Column(
                    children: [
                      _FolderRow(
                        title: 'All Notes',
                        icon: CupertinoIcons.cloud,
                        count: controller.notes.length,
                        onTap: () => controller.selectFolder(null),
                        showEdit: false,
                      ),
                      ...controller.folders.asMap().entries.map((entry) {
                        final folder = entry.value;
                        return _FolderRow(
                          title: folder.name,
                          icon: CupertinoIcons.folder,
                          count: controller.notes
                              .where((note) => note.folderId == folder.id)
                              .length,
                          onTap: () => controller.isEditing.value
                              ? _showFolderActions(context, controller, folder)
                              : controller.selectFolder(folder),
                          showEdit: controller.isEditing.value,
                        );
                      }),
                      _FolderRow(
                        title: 'Recently Deleted',
                        icon: CupertinoIcons.trash,
                        count: controller.trashNotes.length,
                        onTap: controller.openRecentlyDeleted,
                        showEdit: false,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
              if (controller.recentlyDeletedFolders.isNotEmpty) ...[
                const SizedBox(height: 26),
                const _SectionLabel('Recently Deleted Folders'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: _SurfaceCard(
                    child: Column(
                      children: controller.recentlyDeletedFolders
                          .asMap()
                          .entries
                          .map(
                            (entry) => _RestoreFolderRow(
                              folder: entry.value,
                              isLast:
                                  entry.key ==
                                  controller.recentlyDeletedFolders.length - 1,
                              onRestore: () =>
                                  controller.restoreFolder(entry.value),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickCard(
                        label: 'Quick Note',
                        title: controller.notes.isEmpty
                            ? 'Create a new idea'
                            : controller.notes.first.title,
                        icon: CupertinoIcons.square_pencil,
                        onTap: controller.notes.isEmpty
                            ? controller.openCreateNote
                            : () => controller.openNote(controller.notes.first),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickCard(
                        label: 'Smart Category',
                        title: 'Receipts and scans',
                        icon: CupertinoIcons.sparkles,
                        onTap: () => Get.toNamed(AppRoutes.categories),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: controller.openCreateFolder,
                        icon: const Icon(CupertinoIcons.folder_badge_plus),
                        label: const Text('New Folder'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: controller.openCreateNote,
                        icon: const Icon(CupertinoIcons.square_pencil),
                        label: const Text('New Note'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
