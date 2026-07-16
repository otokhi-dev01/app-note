part of 'home_sheets.dart';

class MoveNoteController extends GetxController {
  MoveNoteController({NoteRepository? repository})
    : _repository = repository ?? Get.find<NoteRepository>();

  final NoteRepository _repository;
  final folders = <Folder>[].obs;
  final isLoading = false.obs;

  late final _getFolders = GetFoldersUseCase(_repository);
  late final _createFolder = CreateFolderUseCase(_repository);

  @override
  void onInit() {
    super.onInit();
    loadFolders();
  }

  Future<void> loadFolders() async {
    isLoading.value = true;
    final result = await _getFolders();
    folders.assignAll(result);
    isLoading.value = false;
  }

  Future<void> createFolder(String name) async {
    if (name.trim().isEmpty) return;
    await _createFolder(name.trim());
    await loadFolders();
  }
}

class MoveNoteSheet extends StatefulWidget {
  const MoveNoteSheet({super.key, required this.note, required this.onMove});

  final Note note;
  final ValueChanged<int?> onMove;

  @override
  State<MoveNoteSheet> createState() => _MoveNoteSheetState();
}

class _MoveNoteSheetState extends State<MoveNoteSheet> {
  late final MoveNoteController controller;

  @override
  void initState() {
    super.initState();
    controller = MoveNoteController();
    controller.loadFolders();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);
    final note = widget.note;
    final onMove = widget.onMove;

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
                  icon: const Icon(
                    CupertinoIcons.folder_badge_plus,
                    color: HomeStyle.blue,
                  ),
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
                  ...controller.folders.map(
                    (folder) => Padding(
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
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog(
    BuildContext context,
    MoveNoteController controller,
  ) {
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
    return Material(
      color: isSelected
          ? HomeStyle.blue.withValues(alpha: 0.1)
          : style.secondarySurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? HomeStyle.blue.withValues(alpha: 0.3)
              : style.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
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
            ? const Icon(
                CupertinoIcons.check_mark,
                color: HomeStyle.blue,
                size: 18,
              )
            : Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: style.placeholder,
              ),
      ),
    );
  }
}
