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
    final noteName = note.title.trim().isEmpty
        ? 'this note'
        : '“${note.title}”';

    return _NotesSheet(
      maxHeightFactor: 0.82,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(
            title: 'Move Note',
            subtitle: 'Choose a destination for $noteName.',
            trailing: _SheetIconButton(
              icon: CupertinoIcons.folder_badge_plus,
              tooltip: 'Create a new folder',
              onPressed: () => _showCreateFolderDialog(context, controller),
            ),
          ),
          Flexible(
            child: Obx(() {
              if (controller.isLoading.value) {
                return SizedBox(
                  height: 250,
                  child: Center(
                    child: CupertinoActivityIndicator(
                      color: style.theme.colorScheme.primary,
                    ),
                  ),
                );
              }

              final destinations = <Widget>[
                _FolderTile(
                  style: style,
                  icon: CupertinoIcons.tray_fill,
                  label: 'All Notes',
                  isSelected: note.folderId == null,
                  onTap: () {
                    onMove(null);
                    Get.back();
                  },
                ),
                ...controller.folders.map(
                  (folder) => _FolderTile(
                    style: style,
                    icon: CupertinoIcons.folder_fill,
                    label: folder.name,
                    isSelected: note.folderId == folder.id,
                    onTap: () {
                      onMove(folder.id);
                      Get.back();
                    },
                  ),
                ),
              ];

              return ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 20),
                children: [
                  const _SheetSectionLabel('Locations'),
                  Container(
                    decoration: BoxDecoration(
                      color: style.theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: style.theme.colorScheme.outlineVariant,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < destinations.length;
                          index++
                        ) ...[
                          destinations[index],
                          if (index != destinations.length - 1)
                            Divider(
                              height: 1,
                              indent: 68,
                              color: style.theme.colorScheme.outlineVariant,
                            ),
                        ],
                      ],
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
    Get.dialog<void>(
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
    ).whenComplete(textController.dispose);
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
    final scheme = style.theme.colorScheme;
    final accent = scheme.primary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: isSelected ? accent.withValues(alpha: 0.12) : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 62),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isSelected ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: accent, size: 21),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style.theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (isSelected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.check_mark,
                        color: scheme.onPrimary,
                        size: 14,
                      ),
                    )
                  else
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
      ),
    );
  }
}
