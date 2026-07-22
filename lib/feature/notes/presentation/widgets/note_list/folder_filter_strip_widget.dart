part of '../../view/note_list_view.dart';

class _FolderFilterStrip extends StatelessWidget {
  final List<FolderEntity> folders;
  final int? selectedFolderId;
  final VoidCallback onSelectAll;
  final ValueChanged<int> onSelectFolder;

  const _FolderFilterStrip({
    required this.folders,
    required this.selectedFolderId,
    required this.onSelectAll,
    required this.onSelectFolder,
  });

  @override
  Widget build(BuildContext context) {
    final List<FolderEntity> snapshot = List<FolderEntity>.unmodifiable(
      folders,
    );

    return SizedBox(
      height: 48,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: snapshot.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return _FolderFilterChip(
              label: 'All Notes',
              icon: CupertinoIcons.doc_on_doc,
              selected: selectedFolderId == null,
              onTap: onSelectAll,
            );
          }

          final FolderEntity folder = snapshot[index - 1];

          return _FolderFilterChip(
            key: ValueKey<int>(folder.id),
            label: folder.name.trim().isEmpty ? 'Unnamed' : folder.name.trim(),
            icon: _folderIcon(folder.iconName),
            selected: selectedFolderId == folder.id,
            onTap: () {
              onSelectFolder(folder.id);
            },
          );
        },
      ),
    );
  }
}
