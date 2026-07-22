part of 'folder_list_view.dart';

class _FolderListContent extends StatefulWidget {
  final HomeController controller;

  const _FolderListContent({required this.controller});

  @override
  State<_FolderListContent> createState() {
    return _FolderListContentState();
  }
}

class _FolderListContentState extends State<_FolderListContent> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  _FolderSort _sortMode = _FolderSort.newest;

  HomeController get controller => widget.controller;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color pageColor = theme.scaffoldBackgroundColor;

    return ColoredBox(
      color: pageColor,
      child: Stack(
        children: <Widget>[
          const Positioned.fill(child: _AmbientBackground()),
          Positioned.fill(
            child: Obx(() {
              final List<FolderEntity> folders =
                  List<FolderEntity>.unmodifiable(controller.folders.toList());
              final List<FolderEntity> visibleFolders = _prepareFolders(
                folders,
              );
              final bool isLoading = controller.isFoldersLoading.value;
              final bool hasError = controller.hasFolderError;
              final String errorMessage = controller.folderErrorMessage.value
                  .trim();
              final int? selectedFolderId = controller.selectedFolderId.value;
              final int recentlyDeletedCount = controller.deletedFolders.length;
              final int totalNotes = controller.activeNotes.isNotEmpty
                  ? controller.activeNotes.length
                  : folders.fold<int>(0, (int total, FolderEntity folder) {
                      return total + folder.noteCount;
                    });

              return CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: <Widget>[
                  CupertinoSliverNavigationBar(
                    automaticallyImplyLeading: false,
                    transitionBetweenRoutes: false,
                    stretch: true,
                    border: null,
                    backgroundColor: Colors.transparent,
                    largeTitle: Text(
                      'Folders',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                      ),
                    ),
                    trailing: _NavigationActions(
                      onSortPressed: () {
                        _showSortOptions(context);
                      },
                      onCreatePressed: _openCreateFolder,
                    ),
                  ),
                  CupertinoSliverRefreshControl(
                    onRefresh: controller.loadFolders,
                  ),
                  SliverToBoxAdapter(
                    child: _GlassSearchField(
                      controller: _searchController,
                      onChanged: (String value) {
                        setState(() {
                          _searchQuery = value.trim().toLowerCase();
                        });
                      },
                      onClear: _clearSearch,
                    ),
                  ),
                  if (isLoading && folders.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _FolderLoadingState(),
                    )
                  else if (hasError && folders.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildErrorState(colors, errorMessage),
                    )
                  else if (folders.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(colors),
                    )
                  else ...<Widget>[
                    SliverToBoxAdapter(
                      child: _LibraryOverview(
                        folderCount: folders.length,
                        noteCount: totalNotes,
                        deletedCount: recentlyDeletedCount,
                        allNotesSelected: selectedFolderId == null,
                        onAllNotesPressed: _openAllNotes,
                        onDeletedPressed: _openRecentlyDeleted,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _FolderSectionHeader(
                        count: visibleFolders.length,
                        sortLabel: _sortLabel,
                        onSortPressed: () {
                          _showSortOptions(context);
                        },
                      ),
                    ),
                    if (_searchQuery.isNotEmpty && visibleFolders.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildNoResultsState(colors),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate((
                            BuildContext context,
                            int index,
                          ) {
                            final FolderEntity folder = visibleFolders[index];

                            return _FolderGlassCard(
                              key: ValueKey<int>(folder.id),
                              folder: folder,
                              selected: selectedFolderId == folder.id,
                              onTap: () {
                                _openFolder(folder);
                              },
                              onMore: () {
                                _showFolderActions(context, folder);
                              },
                            );
                          }, childCount: visibleFolders.length),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.05,
                              ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: _FolderFooter(
                        folderCount: folders.length,
                        noteCount: totalNotes,
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return _FolderStatusView(
      icon: CupertinoIcons.folder_badge_plus,
      iconBackgroundColor: colors.primaryContainer,
      iconForegroundColor: colors.onPrimaryContainer,
      title: 'Create Your First Folder',
      message:
          'Organize your notes into folders and keep everything easy to find.',
      messageHeight: 1.4,
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 110),
      action: FilledButton.icon(
        onPressed: _openCreateFolder,
        icon: const Icon(CupertinoIcons.add),
        label: const Text('Create Folder'),
      ),
    );
  }

  Widget _buildNoResultsState(ColorScheme colors) {
    return _FolderStatusView(
      icon: CupertinoIcons.search,
      iconBackgroundColor: colors.surfaceContainerHighest,
      iconForegroundColor: colors.onSurfaceVariant,
      title: 'No Folders Found',
      message: 'No results for “$_searchQuery”.',
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 110),
      actionSpacing: 12,
      action: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onPressed: _clearSearch,
        child: Text(
          'Clear Search',
          style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colors, String errorMessage) {
    return _FolderStatusView(
      icon: CupertinoIcons.exclamationmark_triangle_fill,
      iconBackgroundColor: colors.errorContainer,
      iconForegroundColor: colors.onErrorContainer,
      title: 'Folders Are Unavailable',
      message: errorMessage.isEmpty
          ? 'Unable to load your folders.'
          : errorMessage,
      messageHeight: 1.4,
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 110),
      action: FilledButton.tonalIcon(
        onPressed: () {
          controller.loadFolders();
        },
        icon: const Icon(CupertinoIcons.refresh),
        label: const Text('Try Again'),
      ),
    );
  }

  List<FolderEntity> _prepareFolders(List<FolderEntity> folders) {
    final List<FolderEntity> sorted = folders
        .where((FolderEntity folder) {
          if (_searchQuery.isEmpty) {
            return true;
          }

          return folder.name.trim().toLowerCase().contains(_searchQuery) ||
              folder.iconName.trim().toLowerCase().contains(_searchQuery);
        })
        .toList(growable: false);

    sorted.sort(_compareFolders);
    return sorted;
  }

  int _compareFolders(FolderEntity first, FolderEntity second) {
    switch (_sortMode) {
      case _FolderSort.newest:
        return _folderDate(second).compareTo(_folderDate(first));
      case _FolderSort.oldest:
        return _folderDate(first).compareTo(_folderDate(second));
      case _FolderSort.name:
        return first.name.toLowerCase().compareTo(second.name.toLowerCase());
      case _FolderSort.noteCount:
        return second.noteCount.compareTo(first.noteCount);
    }
  }

  DateTime _folderDate(FolderEntity folder) {
    return folder.updatedAt ?? folder.createdAt ?? DateTime(1970);
  }

  String get _sortLabel {
    switch (_sortMode) {
      case _FolderSort.newest:
        return 'Newest';
      case _FolderSort.oldest:
        return 'Oldest';
      case _FolderSort.name:
        return 'Name';
      case _FolderSort.noteCount:
        return 'Most Notes';
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  void _openAllNotes() {
    HapticFeedback.selectionClick();
    FocusManager.instance.primaryFocus?.unfocus();
    controller.selectAllNotes();
    _openNotesTab();
  }

  void _openFolder(FolderEntity folder) {
    HapticFeedback.selectionClick();
    FocusManager.instance.primaryFocus?.unfocus();
    controller.selectFolder(folder.id);
    _openNotesTab();
  }

  void _openNotesTab() {
    if (Get.isRegistered<MainNavigationController>()) {
      Get.find<MainNavigationController>().changeTab(1);
    }
  }

  Future<void> _openCreateFolder() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final dynamic result = await Get.toNamed(AppRoutes.createFolder);

    if (result == true) {
      await controller.loadFolders();
    }
  }

  Future<void> _openRecentlyDeleted() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Get.toNamed(AppRoutes.recentlyDeletedFolders);
    await controller.loadFolders();
  }

  Future<void> _showSortOptions(BuildContext context) async {
    HapticFeedback.selectionClick();

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return CupertinoActionSheet(
          title: const Text('Sort Folders'),
          message: const Text('Choose how folders are ordered.'),
          actions: <Widget>[
            _buildSortAction(
              sheetContext: sheetContext,
              title: 'Newest First',
              icon: CupertinoIcons.clock_fill,
              mode: _FolderSort.newest,
            ),
            _buildSortAction(
              sheetContext: sheetContext,
              title: 'Oldest First',
              icon: CupertinoIcons.time,
              mode: _FolderSort.oldest,
            ),
            _buildSortAction(
              sheetContext: sheetContext,
              title: 'Folder Name',
              icon: CupertinoIcons.textformat_abc,
              mode: _FolderSort.name,
            ),
            _buildSortAction(
              sheetContext: sheetContext,
              title: 'Most Notes',
              icon: CupertinoIcons.doc_on_doc_fill,
              mode: _FolderSort.noteCount,
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

  Widget _buildSortAction({
    required BuildContext sheetContext,
    required String title,
    required IconData icon,
    required _FolderSort mode,
  }) {
    return _SortAction(
      title: title,
      icon: icon,
      selected: _sortMode == mode,
      onPressed: () {
        Navigator.of(sheetContext).pop();
        setState(() {
          _sortMode = mode;
        });
      },
    );
  }

  Future<void> _showFolderActions(
    BuildContext context,
    FolderEntity folder,
  ) async {
    HapticFeedback.mediumImpact();
    final String folderName = folder.name.trim().isEmpty
        ? 'Unnamed Folder'
        : folder.name.trim();

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return CupertinoActionSheet(
          title: Text(folderName),
          message: Text(
            '${folder.noteCount} '
            '${folder.noteCount == 1 ? 'note' : 'notes'}',
          ),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _openFolder(folder);
              },
              child: const _ActionSheetLabel(
                icon: CupertinoIcons.folder_open,
                label: 'Open Folder',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _showRenameDialog(context, folder);
              },
              child: const _ActionSheetLabel(
                icon: CupertinoIcons.pencil,
                label: 'Rename Folder',
              ),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _confirmDelete(context, folder);
              },
              child: const _ActionSheetLabel(
                icon: CupertinoIcons.delete,
                label: 'Move to Recently Deleted',
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

  Future<void> _showRenameDialog(
    BuildContext context,
    FolderEntity folder,
  ) async {
    final TextEditingController nameController = TextEditingController(
      text: folder.name,
    );
    final String? newName = await showCupertinoDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final ColorScheme colors = Theme.of(dialogContext).colorScheme;

        return CupertinoAlertDialog(
          title: const Text('Rename Folder'),
          content: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: CupertinoTextField(
              controller: nameController,
              autofocus: true,
              placeholder: 'Folder name',
              clearButtonMode: OverlayVisibilityMode.editing,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              onSubmitted: (String value) {
                final String name = value.trim();

                if (name.isNotEmpty) {
                  Navigator.of(dialogContext).pop(name);
                }
              },
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final String name = nameController.text.trim();

                if (name.isNotEmpty) {
                  Navigator.of(dialogContext).pop(name);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();

    if (newName == null || newName.trim().isEmpty) {
      return;
    }

    await controller.updateFolder(folder: folder, name: newName.trim());
  }

  Future<void> _confirmDelete(BuildContext context, FolderEntity folder) async {
    final String folderName = folder.name.trim().isEmpty
        ? 'Unnamed Folder'
        : folder.name.trim();
    final bool? confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Delete Folder?'),
          content: Text(
            '“$folderName” will be moved to Recently Deleted. '
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
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await controller.deleteOrRestoreFolder(
        folderId: folder.id,
        isDelete: true,
      );
    }
  }
}
