import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/data/models/note_model.dart';
import 'package:notes/data/models/folder_model.dart';
import 'package:notes/domain/repositories/note_repository.dart';
import '../home_style.dart';

class RecentlyDeletedSheet extends StatelessWidget {
  const RecentlyDeletedSheet({
    super.key,
    required this.notes,
    required this.onRestore,
    required this.onDeletePermanently,
    this.onClearAll,
  });

  final List<NoteModel> notes;
  final Function(NoteModel) onRestore;
  final Function(NoteModel) onDeletePermanently;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);
    final trashNotes = notes.toList();

    return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: style.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: style.placeholder,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recently Deleted',
                        style: style.theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                      if (trashNotes.isNotEmpty && onClearAll != null)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: onClearAll,
                          child: const Text(
                            'Empty Trash',
                            style: TextStyle(
                              color: HomeStyle.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Get.back(),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: HomeStyle.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            if (trashNotes.isEmpty)
              _EmptyTrashState(style: style)
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  itemCount: trashNotes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final note = trashNotes[index];
                    return _DeletedNoteCard(
                      style: style,
                      note: note,
                      onRestore: () => onRestore(note),
                      onDelete: () => _confirmDelete(context, note),
                    );
                  },
                ),
              ),
          ],
        ),
      );
  }

  void _confirmDelete(BuildContext context, NoteModel note) {
    Get.dialog(
      CupertinoAlertDialog(
        title: const Text('Permanently Delete?'),
        content: const Text('This action cannot be undone and will remove the note forever.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Get.back(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              onDeletePermanently(note);
              Get.back();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class MoveNoteController extends GetxController {
  final NoteRepository _repository = Get.find<NoteRepository>();
  final folders = <FolderModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadFolders();
  }

  Future<void> loadFolders() async {
    isLoading.value = true;
    final result = await _repository.getFolders();
    folders.value = result.map((f) => FolderModel.fromEntity(f)).toList();
    isLoading.value = false;
  }

  Future<void> createFolder(String name) async {
    if (name.trim().isEmpty) return;
    await _repository.createFolder(name.trim());
    await loadFolders();
  }
}

class MoveNoteSheet extends StatelessWidget {
  const MoveNoteSheet({
    super.key,
    required this.note,
    required this.onMove,
  });

  final NoteModel note;
  final Function(int?) onMove;

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);
    final controller = Get.put(MoveNoteController());

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: style.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: style.placeholder,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Move Note',
                  style: style.theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.folder_badge_plus, color: HomeStyle.blue),
                  onPressed: () => _showCreateFolderDialog(context, controller),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          Flexible(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CupertinoActivityIndicator());
              }

              return ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  _FolderTile(
                    style: style,
                    icon: CupertinoIcons.tray,
                    label: 'All Notes',
                    isSelected: note.folderId == null,
                    onTap: () {
                      onMove(null);
                      Get.back();
                    },
                  ),
                  const SizedBox(height: 12),
                  ...controller.folders.map((folder) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FolderTile(
                          style: style,
                          icon: CupertinoIcons.folder,
                          label: folder.name,
                          isSelected: note.folderId == folder.id,
                          onTap: () {
                            onMove(folder.id);
                            Get.back();
                          },
                        ),
                      )),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context, MoveNoteController controller) {
    final textController = TextEditingController();
    Get.dialog(
      CupertinoAlertDialog(
        title: const Text('New Folder'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: textController,
            placeholder: 'Folder Name',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Get.back(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              controller.createFolder(textController.text);
              Get.back();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class ShareBottomSheet extends StatelessWidget {
  const ShareBottomSheet({super.key, required this.note});
  final NoteModel note;

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
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
            onTap: () {
              Get.back();
              Get.snackbar('Copied', 'Note content copied to clipboard.');
            },
          ),
          _ShareOption(
            icon: CupertinoIcons.chat_bubble,
            label: 'Send via Messages',
            onTap: () => Get.back(),
          ),
          _ShareOption(
            icon: CupertinoIcons.mail,
            label: 'Send via Mail',
            onTap: () => Get.back(),
          ),
          _ShareOption(
            icon: CupertinoIcons.share,
            label: 'More Options...',
            onTap: () => Get.back(),
          ),
        ],
      ),
    );
  }
}

class _EmptyTrashState extends StatelessWidget {
  const _EmptyTrashState({required this.style});
  final HomeStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.trash_slash,
            size: 64,
            color: style.placeholder,
          ),
          const SizedBox(height: 16),
          Text(
            'Trash is empty',
            style: style.theme.textTheme.titleMedium?.copyWith(
              color: style.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeletedNoteCard extends StatelessWidget {
  const _DeletedNoteCard({
    required this.style,
    required this.note,
    required this.onRestore,
    required this.onDelete,
  });

  final HomeStyle style;
  final NoteModel note;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.secondarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: style.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.title.isEmpty ? 'Untitled' : note.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            note.content.isEmpty ? 'No content' : note.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: style.secondaryText, fontSize: 14, height: 1.3),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionButton(
                label: 'Restore',
                icon: CupertinoIcons.arrow_counterclockwise,
                color: HomeStyle.blue,
                onPressed: onRestore,
              ),
              const SizedBox(width: 12),
              _ActionButton(
                label: 'Delete',
                icon: CupertinoIcons.trash,
                color: HomeStyle.red,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.style,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final HomeStyle style;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? HomeStyle.blue.withValues(alpha: 0.1) : style.secondarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? HomeStyle.blue.withValues(alpha: 0.3) : style.border,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(
          icon,
          color: isSelected ? HomeStyle.blue : style.secondaryText,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? HomeStyle.blue : style.primaryText,
          ),
        ),
        trailing: isSelected
            ? const Icon(CupertinoIcons.check_mark, color: HomeStyle.blue, size: 18)
            : Icon(CupertinoIcons.chevron_right, size: 16, color: style.placeholder),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      minimumSize: Size.zero,
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return ListTile(
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
      trailing: Icon(CupertinoIcons.chevron_right, size: 14, color: style.placeholder),
    );
  }
}
