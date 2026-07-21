part of '../../view/note_list_view.dart';

class _NoteListContent extends StatefulWidget {
  final HomeController controller;

  const _NoteListContent({required this.controller});

  @override
  State<_NoteListContent> createState() {
    return _NoteListContentState();
  }
}

class _NoteListContentState extends State<_NoteListContent> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  HomeController get controller => widget.controller;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color pageColor = theme.scaffoldBackgroundColor;

    return ColoredBox(
      color: pageColor,
      child: Obx(() {
        final List<FolderEntity> folders = List<FolderEntity>.unmodifiable(
          controller.folders.toList(),
        );

        final List<NoteEntity> notes = List<NoteEntity>.unmodifiable(
          controller.visibleNotes,
        );

        final List<NoteEntity> visibleNotes = _filterNotes(
          notes: notes,
          folders: folders,
        );

        final List<NoteEntity> pinnedNotes = visibleNotes
            .where((NoteEntity note) => note.isPinned)
            .toList(growable: false);

        final List<NoteEntity> regularNotes = visibleNotes
            .where((NoteEntity note) => !note.isPinned)
            .toList(growable: false);

        final bool isInitialLoading =
            controller.isNotesLoading.value && controller.notes.isEmpty;

        final String errorMessage = _cleanServerMessage(
          controller.noteErrorMessage.value,
        );

        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: <Widget>[
            CupertinoSliverNavigationBar(
              automaticallyImplyLeading: false,
              stretch: true,
              border: null,
              backgroundColor: pageColor.withValues(alpha: 0.94),
              largeTitle: Text(
                controller.selectedFolderName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              trailing: _CreateNoteButton(onPressed: _openCreateNoteScreen),
            ),

            CupertinoSliverRefreshControl(onRefresh: controller.loadAll),

            SliverToBoxAdapter(
              child: _NoteSearchField(
                controller: _searchController,
                onChanged: (String value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
                onClear: _clearSearch,
              ),
            ),

            SliverToBoxAdapter(
              child: _FolderFilterStrip(
                folders: folders,
                selectedFolderId: controller.selectedFolderId.value,
                onSelectAll: () {
                  HapticFeedback.selectionClick();
                  controller.selectAllNotes();
                },
                onSelectFolder: (int folderId) {
                  HapticFeedback.selectionClick();
                  controller.selectFolder(folderId);
                },
              ),
            ),

            if (isInitialLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _NoteLoadingState(),
              )
            else if (controller.hasNoteError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _NoteErrorState(
                  message: errorMessage,
                  onRetry: controller.loadNotes,
                ),
              )
            else if (notes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyNoteState(
                  hasFolders: folders.isNotEmpty,
                  onCreate: _openCreateNoteScreen,
                ),
              )
            else if (visibleNotes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _NoNoteResultsState(
                  query: _searchQuery,
                  onClear: _clearSearch,
                ),
              )
            else ...<Widget>[
              SliverToBoxAdapter(
                child: _NoteCountSummary(count: visibleNotes.length),
              ),

              if (pinnedNotes.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Pinned',
                    count: pinnedNotes.length,
                    icon: CupertinoIcons.pin_fill,
                  ),
                ),
                _buildNoteSection(
                  context: context,
                  notes: pinnedNotes,
                  folders: folders,
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
              ],

              if (regularNotes.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: pinnedNotes.isEmpty ? 'Notes' : 'Other Notes',
                    count: regularNotes.length,
                    icon: CupertinoIcons.doc_text_fill,
                  ),
                ),
                _buildNoteSection(
                  context: context,
                  notes: regularNotes,
                  folders: folders,
                ),
              ],

              SliverToBoxAdapter(
                child: _NoteFooter(count: visibleNotes.length),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 130)),
          ],
        );
      }),
    );
  }

  Widget _buildNoteSection({
    required BuildContext context,
    required List<NoteEntity> notes,
    required List<FolderEntity> folders,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.builder(
        itemCount: notes.length,
        itemBuilder: (BuildContext context, int index) {
          final NoteEntity note = notes[index];

          final FolderEntity? folder = _folderForNote(
            note: note,
            folders: folders,
          );

          final Color folderColor = _parseFolderColor(
            folder?.colorValue ?? '',
            Theme.of(context).colorScheme.primary,
          );

          return Padding(
            key: ValueKey<int>(note.id),
            padding: EdgeInsets.only(
              bottom: index == notes.length - 1 ? 0 : 10,
            ),
            child: _NoteRow(
              note: note,
              folderName: _folderNameFor(note: note, folder: folder),
              folderColor: folderColor,
              onTap: () {
                HapticFeedback.selectionClick();
                controller.openNote(note.id);
              },
              onMore: () {
                _showNoteActions(context, note);
              },
            ),
          );
        },
      ),
    );
  }

  List<NoteEntity> _filterNotes({
    required List<NoteEntity> notes,
    required List<FolderEntity> folders,
  }) {
    if (_searchQuery.isEmpty) {
      return notes;
    }

    return notes
        .where((NoteEntity note) {
          final FolderEntity? folder = _folderForNote(
            note: note,
            folders: folders,
          );

          final String title = note.title.trim().toLowerCase();

          final String folderName = _folderNameFor(
            note: note,
            folder: folder,
          ).toLowerCase();

          final String preview = _notePreview(note).toLowerCase();

          return title.contains(_searchQuery) ||
              folderName.contains(_searchQuery) ||
              preview.contains(_searchQuery);
        })
        .toList(growable: false);
  }

  FolderEntity? _folderForNote({
    required NoteEntity note,
    required List<FolderEntity> folders,
  }) {
    for (final FolderEntity folder in folders) {
      if (folder.id == note.folderId) {
        return folder;
      }
    }

    return null;
  }

  String _folderNameFor({
    required NoteEntity note,
    required FolderEntity? folder,
  }) {
    if (folder != null) {
      final String name = folder.name.trim();

      return name.isEmpty ? 'Unnamed Folder' : name;
    }

    final String responseName = note.folderName.trim();

    return responseName.isEmpty ? 'Notes' : responseName;
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
    });
  }

  Future<void> _openCreateNoteScreen() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (controller.folders.isEmpty) {
      Get.snackbar(
        'Folder required',
        'Create a folder before creating a note.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    await Get.toNamed(AppRoutes.createNote);

    await controller.loadAll();
  }

  Future<void> _showNoteActions(BuildContext context, NoteEntity note) async {
    HapticFeedback.mediumImpact();

    final String title = note.title.trim().isEmpty
        ? 'Untitled Note'
        : note.title.trim();

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return CupertinoActionSheet(
          title: Text(title),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();

                controller.openNote(note.id);
              },
              child: const _ActionSheetLabel(
                icon: CupertinoIcons.doc_text,
                label: 'Open Note',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();

                controller.togglePin(note);
              },
              child: _ActionSheetLabel(
                icon: CupertinoIcons.pin,
                label: note.isPinned ? 'Unpin Note' : 'Pin Note',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();

                controller.lockNote(note);
              },
              child: _ActionSheetLabel(
                icon: note.isLocked
                    ? CupertinoIcons.lock_open
                    : CupertinoIcons.lock,
                label: note.isLocked ? 'Unlock Note' : 'Lock Note',
              ),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(sheetContext).pop();

                _confirmArchiveNote(context, note);
              },
              child: const _ActionSheetLabel(
                icon: CupertinoIcons.delete,
                label: 'Move to Recycle Bin',
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetContext).pop();
            },
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  Future<void> _confirmArchiveNote(
    BuildContext context,
    NoteEntity note,
  ) async {
    final String title = note.title.trim().isEmpty
        ? 'Untitled Note'
        : note.title.trim();

    final bool? confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Move Note to Recycle Bin?'),
          content: Text(
            '“$title” will be removed '
            'from your active notes. '
            'You can restore it later.',
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Move'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await controller.archiveNote(note);
  }

  String _cleanServerMessage(String message) {
    if (message.contains('PlainText') || message.contains('PreviewText')) {
      return 'The backend note database '
          'is missing the PlainText and '
          'PreviewText columns. The database '
          'migration or note query must be '
          'corrected before notes can load.';
    }

    return message;
  }
}
