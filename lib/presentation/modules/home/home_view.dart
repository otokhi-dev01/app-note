import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:notes/app/routes/app_routes.dart';
import 'package:notes/app/theme/colors.dart';
import 'package:notes/core/utils/image_helper.dart';
import 'package:notes/domain/entities/folder.dart';
import 'package:notes/domain/entities/note.dart';

import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isTrashView.value) {
        return _DeletedPage(controller: controller);
      }

      return Scaffold(
        body: IndexedStack(
          index: controller.selectedTab.value,
          children: [
            _NotesPage(controller: controller),
            _FoldersPage(controller: controller),
            _SearchPage(controller: controller),
            _GoalsPage(controller: controller),
          ],
        ),
        floatingActionButton: controller.selectedTab.value <= 1
            ? FloatingActionButton(
                key: const ValueKey('compose_note_button'),
                onPressed: controller.openCreateNote,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: const Icon(CupertinoIcons.square_pencil),
              )
            : null,
        bottomNavigationBar: _LinenNavigationBar(
          selectedIndex: controller.selectedTab.value,
          onSelect: controller.selectTab,
        ),
      );
    });
  }
}

class _NotesPage extends StatelessWidget {
  const _NotesPage({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Obx(() {
        final pinned = controller.pinnedNotes;
        final notes = controller.filteredNotes;
        return RefreshIndicator(
          onRefresh: controller.loadNotes,
          color: AppColors.primary,
          child: CustomScrollView(
            key: const PageStorageKey('notes_page'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _LinenHeader(
                  eyebrow: controller.selectedFolder.value == null
                      ? 'YOUR LIBRARY'
                      : 'FOLDER',
                  title: controller.selectedFolder.value?.name ?? 'Notes',
                  onMenu: () => _showAppMenu(context, controller),
                  actions: [
                    IconButton(
                      onPressed: controller.toggleViewMode,
                      tooltip: controller.isGalleryView.value
                          ? 'List view'
                          : 'Gallery view',
                      icon: Icon(
                        controller.isGalleryView.value
                            ? CupertinoIcons.list_bullet
                            : CupertinoIcons.square_grid_2x2,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: controller.goToSettings,
                      icon: const Icon(
                        CupertinoIcons.ellipsis_vertical,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: _SearchField(
                    hint: 'Search notes',
                    readOnly: true,
                    onTap: () => controller.selectTab(2),
                  ),
                ),
              ),
              if (controller.isLoading.value)
                const SliverFillRemaining(
                  child: Center(child: CupertinoActivityIndicator()),
                )
              else if (controller.errorMessage.value != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(
                    message: controller.errorMessage.value!,
                    onRetry: controller.loadNotes,
                  ),
                )
              else if (pinned.isEmpty && notes.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: CupertinoIcons.doc_text,
                    title: 'Start your first note',
                    message: 'Capture an idea, checklist, scan, or drawing.',
                    actionLabel: 'New Note',
                    onAction: controller.openCreateNote,
                  ),
                )
              else ...[
                if (pinned.isNotEmpty) ...[
                  const _SliverSectionTitle(title: 'PINNED'),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: _PinnedCard(
                        note: pinned.first,
                        onTap: () => controller.openNote(pinned.first),
                        onShare: () => controller.shareNote(pinned.first),
                      ),
                    ),
                  ),
                ],
                _SliverSectionTitle(
                  title:
                      controller.selectedFolder.value?.name.toUpperCase() ??
                      'ALL NOTES',
                  trailing: '${pinned.length + notes.length} notes',
                ),
                if (controller.isGalleryView.value)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: .88,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _NoteGalleryCard(
                          note: notes[index],
                          onTap: () => controller.openNote(notes[index]),
                        ),
                        childCount: notes.length,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: _NoteGroup(notes: notes, controller: controller),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _FoldersPage extends StatelessWidget {
  const _FoldersPage({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Obx(() {
        return RefreshIndicator(
          onRefresh: controller.loadNotes,
          color: AppColors.primary,
          child: ListView(
            key: const PageStorageKey('folders_page'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              _LinenHeader(
                title: 'Folders',
                onMenu: () => _showAppMenu(context, controller),
                actions: [
                  IconButton(
                    onPressed: controller.isFolderSyncing.value
                        ? null
                        : controller.syncFolders,
                    tooltip: 'Sync folders',
                    icon: controller.isFolderSyncing.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            CupertinoIcons.cloud_download,
                            color: AppColors.primary,
                          ),
                  ),
                  TextButton(
                    onPressed: controller.toggleEdit,
                    child: Text(controller.isEditing.value ? 'Done' : 'Edit'),
                  ),
                  IconButton(
                    onPressed: controller.goToSettings,
                    icon: const Icon(
                      CupertinoIcons.ellipsis_vertical,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (controller.isFolderSyncing.value)
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.primary,
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
                child: _SearchField(
                  hint: 'Search folders and notes',
                  readOnly: true,
                  onTap: () => controller.selectTab(2),
                ),
              ),
              const _SectionLabel('ON MY DEVICE'),
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
                const _SectionLabel('RECENTLY DELETED FOLDERS'),
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
                        label: 'QUICK NOTE',
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
                        label: 'SMART CATEGORY',
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

class _SearchPage extends StatelessWidget {
  const _SearchPage({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Obx(() {
        final hasFilter =
            controller.searchQuery.value.isNotEmpty ||
            controller.activeSearchToken.value != null;
        return ListView(
          key: const PageStorageKey('search_page'),
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            _LinenHeader(
              title: 'Search',
              onMenu: () => _showAppMenu(context, controller),
              actions: [
                TextButton(
                  onPressed: controller.clearRecentSearches,
                  child: const Text('Clear'),
                ),
                IconButton(
                  onPressed: controller.goToSettings,
                  icon: const Icon(
                    CupertinoIcons.ellipsis_vertical,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: TextField(
                controller: controller.searchFieldController,
                autofocus: false,
                onChanged: controller.search,
                onSubmitted: controller.addRecentSearch,
                decoration: InputDecoration(
                  hintText: 'Search notes, tags, and attachments',
                  prefixIcon: const Icon(CupertinoIcons.search),
                  suffixIcon: controller.searchQuery.value.isEmpty
                      ? const Icon(CupertinoIcons.mic, size: 20)
                      : IconButton(
                          onPressed: () => controller.search(''),
                          icon: const Icon(CupertinoIcons.xmark_circle_fill),
                        ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            if (controller.activeSearchToken.value != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    label: Text(controller.activeSearchToken.value!),
                    onDeleted: controller.removeSearchToken,
                    deleteIcon: const Icon(CupertinoIcons.xmark, size: 14),
                  ),
                ),
              ),
            if (hasFilter) ...[
              _SectionHeading(
                title: 'Results',
                trailing: '${controller.filteredNotes.length} found',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: controller.filteredNotes.isEmpty
                    ? const _InlineEmpty(message: 'No matching notes found.')
                    : _NoteGroup(
                        notes: controller.filteredNotes,
                        controller: controller,
                      ),
              ),
            ] else ...[
              const _SectionHeading(title: 'Media Types'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _MediaTypeCard(
                      icon: CupertinoIcons.photo,
                      label: 'Photos',
                      onTap: () => controller.searchByFilter('attachments'),
                    ),
                    _MediaTypeCard(
                      icon: CupertinoIcons.doc_text_viewfinder,
                      label: 'Scans',
                      onTap: () => Get.toNamed(AppRoutes.media),
                    ),
                    _MediaTypeCard(
                      icon: CupertinoIcons.pencil_outline,
                      label: 'Drawings',
                      onTap: () => controller.searchByFilter('drawings'),
                    ),
                    _MediaTypeCard(
                      icon: CupertinoIcons.paperclip,
                      label: 'Files',
                      onTap: () => controller.searchByFilter('attachments'),
                    ),
                  ],
                ),
              ),
              if (controller.recentSearches.isNotEmpty) ...[
                const _SectionHeading(title: 'Recent Searches'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SurfaceCard(
                    child: Column(
                      children: controller.recentSearches
                          .take(4)
                          .toList()
                          .asMap()
                          .entries
                          .map(
                            (entry) => _RecentSearchRow(
                              value: entry.value,
                              isLast:
                                  entry.key ==
                                  controller.recentSearches.take(4).length - 1,
                              onTap: () => controller.search(entry.value),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
              const _SectionHeading(title: 'Discovery Tags'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _extractTags(controller.notes).map((tag) {
                    return ActionChip(
                      label: Text(tag),
                      onPressed: () => controller.search(tag),
                    );
                  }).toList(),
                ),
              ),
              const _SectionHeading(title: 'Smart Categories'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 104,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CategoryChip(
                        title: 'Receipts',
                        icon: CupertinoIcons.doc_text_search,
                        onTap: () => controller.searchCategory('Receipts'),
                      ),
                      _CategoryChip(
                        title: 'Travel',
                        icon: CupertinoIcons.airplane,
                        onTap: () => controller.searchCategory('Travel'),
                      ),
                      _CategoryChip(
                        title: 'Work',
                        icon: CupertinoIcons.briefcase,
                        onTap: () => controller.searchCategory('Work'),
                      ),
                      _CategoryChip(
                        title: 'Personal',
                        icon: CupertinoIcons.person,
                        onTap: () => controller.searchCategory('Personal'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _GoalsPage extends StatelessWidget {
  const _GoalsPage({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Obx(() {
        final todayWords = controller.notes
            .where(
              (note) => DateUtils.isSameDay(note.updatedAt, DateTime.now()),
            )
            .fold<int>(0, (sum, note) => sum + _wordCount(note.content));
        const dailyGoal = 2000;
        final progress = (todayWords / dailyGoal).clamp(0.0, 1.0);
        final activeDates = controller.notes
            .map((note) => DateUtils.dateOnly(note.updatedAt))
            .toSet();
        final totalWords = controller.notes.fold<int>(
          0,
          (sum, note) => sum + _wordCount(note.content),
        );
        return RefreshIndicator(
          onRefresh: controller.loadNotes,
          color: AppColors.primary,
          child: ListView(
            key: const PageStorageKey('goals_page'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              _LinenHeader(
                eyebrow: 'WRITING DASHBOARD',
                title: 'Compete',
                onMenu: () => _showAppMenu(context, controller),
                actions: [
                  IconButton(
                    onPressed: () => Get.toNamed(AppRoutes.calendar),
                    icon: const Icon(
                      CupertinoIcons.calendar,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: controller.goToSettings,
                    icon: const Icon(
                      CupertinoIcons.ellipsis_vertical,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _SurfaceCard(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 174,
                        height: 174,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 14,
                              color: AppColors.primary,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              strokeCap: StrokeCap.round,
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(progress * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Text(
                                    'of Daily Goal',
                                    style: TextStyle(color: AppColors.subtitle),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        '${NumberFormat.decimalPattern().format(todayWords)} / ${NumberFormat.decimalPattern().format(dailyGoal)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Words written today',
                        style: TextStyle(color: AppColors.subtitle),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: CupertinoIcons.flame_fill,
                        value: '${activeDates.length}',
                        label: 'Active days',
                        accent: AppColors.yellow,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        icon: CupertinoIcons.text_cursor,
                        value: NumberFormat.compact().format(totalWords),
                        label: 'Total words',
                        accent: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const _SectionHeading(title: 'Weekly Progress'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _WeeklyProgress(activeDates: activeDates),
              ),
              const _SectionHeading(title: 'Milestones'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SurfaceCard(
                  child: Column(
                    children: [
                      _MilestoneRow(
                        title: 'First 1,000 Words',
                        subtitle: 'Build momentum with your first draft',
                        complete: totalWords >= 1000,
                      ),
                      _MilestoneRow(
                        title: 'Organized Writer',
                        subtitle: 'Create five focused folders',
                        complete: controller.folders.length >= 5,
                      ),
                      _MilestoneRow(
                        title: 'Visual Thinker',
                        subtitle: 'Add five photos or drawings',
                        complete:
                            controller.notes.fold<int>(
                              0,
                              (sum, note) => sum + note.imagePaths.length,
                            ) >=
                            5,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _DeletedPage extends StatelessWidget {
  const _DeletedPage({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          return Column(
            children: [
              _CompactBar(
                title: 'Recently Deleted',
                onBack: controller.showFolders,
                actionLabel: 'Edit',
                onAction: () {},
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
                  children: [
                    const Text(
                      'Notes are available here for 30 days. After that time, notes can be permanently deleted.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.subtitle,
                        fontSize: 17,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (controller.trashNotes.isEmpty)
                      const _InlineEmpty(message: 'Recently Deleted is empty.')
                    else
                      _SurfaceCard(
                        child: Column(
                          children: controller.trashNotes
                              .asMap()
                              .entries
                              .map(
                                (entry) => _DeletedRow(
                                  note: entry.value,
                                  isLast:
                                      entry.key ==
                                      controller.trashNotes.length - 1,
                                  onTap: () => _showDeletedActions(
                                    context,
                                    controller,
                                    entry.value,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.paddingOf(context).bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: controller.trashNotes.isEmpty
                          ? null
                          : controller.clearTrash,
                      child: const Text(
                        'Delete All',
                        style: TextStyle(color: AppColors.red),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: controller.trashNotes.isEmpty
                          ? null
                          : controller.restoreAllNotes,
                      child: const Text('Recover All'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _LinenHeader extends StatelessWidget {
  const _LinenHeader({
    required this.title,
    required this.onMenu,
    this.eyebrow,
    this.actions = const [],
  });

  final String title;
  final String? eyebrow;
  final VoidCallback onMenu;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onMenu,
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: const Icon(CupertinoIcons.line_horizontal_3),
              ),
              const Spacer(),
              ...actions,
            ],
          ),
          const SizedBox(height: 12),
          if (eyebrow != null) ...[
            Text(eyebrow!, style: _eyebrowStyle),
            const SizedBox(height: 5),
          ],
          Text(
            title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 38,
              letterSpacing: -1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactBar extends StatelessWidget {
  const _CompactBar({
    required this.title,
    required this.onBack,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final VoidCallback onBack;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(CupertinoIcons.chevron_left, size: 18),
            label: const Text('Folders'),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(
            width: 86,
            child: actionLabel == null
                ? null
                : TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ),
        ],
      ),
    );
  }
}

class _LinenNavigationBar extends StatelessWidget {
  const _LinenNavigationBar({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const items = [
      (CupertinoIcons.doc_text, 'Notes'),
      (CupertinoIcons.folder, 'Folders'),
      (CupertinoIcons.search, 'Search'),
      (CupertinoIcons.scope, 'Goals'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        MediaQuery.paddingOf(context).bottom + 7,
      ),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final selected = selectedIndex == entry.key;
          final color = selected ? AppColors.primary : AppColors.subtitle;
          return Expanded(
            child: Semantics(
              selected: selected,
              button: true,
              label: entry.value.$2,
              child: InkResponse(
                onTap: () => onSelect(entry.key),
                radius: 30,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(entry.value.$1, color: color, size: 24),
                      const SizedBox(height: 3),
                      Text(
                        entry.value.$2,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, this.readOnly = false, this.onTap});

  final String hint;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(CupertinoIcons.search),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
  }
}

class _NoteGroup extends StatelessWidget {
  const _NoteGroup({required this.notes, required this.controller});

  final List<Note> notes;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        children: notes.asMap().entries.map((entry) {
          final note = entry.value;
          return _NoteRow(
            note: note,
            isLast: entry.key == notes.length - 1,
            onTap: () => controller.openNote(note),
            onAction: (action) => _handleNoteAction(action, note, controller),
          );
        }).toList(),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({
    required this.note,
    required this.isLast,
    required this.onTap,
    required this.onAction,
  });

  final Note note;
  final bool isLast;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  if (note.imagePaths.isNotEmpty) ...[
                    ImageHelper.buildSafeImage(
                      note.imagePaths.first,
                      width: 48,
                      height: 48,
                      radius: 9,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (note.isPinned) ...[
                              const Icon(
                                CupertinoIcons.pin_fill,
                                size: 13,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 5),
                            ],
                            Expanded(
                              child: Text(
                                note.title.isEmpty ? 'Untitled' : note.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_shortDate(note.updatedAt)}  ${note.content.isEmpty ? 'No additional text' : note.content}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.subtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Note actions',
                    onSelected: onAction,
                    icon: const Icon(
                      CupertinoIcons.ellipsis,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Text(note.isPinned ? 'Unpin' : 'Pin'),
                      ),
                      const PopupMenuItem(value: 'share', child: Text('Share')),
                      const PopupMenuItem(value: 'move', child: Text('Move')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: AppColors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Divider(height: 1),
          ),
      ],
    );
  }
}

class _NoteGalleryCard extends StatelessWidget {
  const _NoteGalleryCard({required this.note, required this.onTap});

  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.imagePaths.isNotEmpty)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ImageHelper.buildSafeImage(
                      note.imagePaths.first,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.doc_text,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                note.title.isEmpty ? 'Untitled' : note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                note.content.isEmpty
                    ? _shortDate(note.updatedAt)
                    : note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinnedCard extends StatelessWidget {
  const _PinnedCard({
    required this.note,
    required this.onTap,
    required this.onShare,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    CupertinoIcons.pin_fill,
                    size: 18,
                    color: colors.onPrimaryContainer,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onShare,
                    icon: Icon(
                      CupertinoIcons.share,
                      size: 20,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              Text(
                note.title.isEmpty ? 'Untitled' : note.title,
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                note.content.isEmpty ? 'No additional text' : note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Updated ${_shortDate(note.updatedAt)}',
                style: TextStyle(
                  color: colors.onPrimaryContainer.withValues(alpha: .68),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(label, style: const TextStyle(color: AppColors.subtitle)),
        ],
      ),
    );
  }
}

class _WeeklyProgress extends StatelessWidget {
  const _WeeklyProgress({required this.activeDates});

  final Set<DateTime> activeDates;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return _SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final date = monday.add(Duration(days: index));
          final complete = activeDates.contains(date);
          return Column(
            children: [
              Text(DateFormat.E().format(date).substring(0, 1)),
              const SizedBox(height: 9),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: complete
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: date == today
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: complete
                    ? const Icon(
                        CupertinoIcons.check_mark,
                        size: 17,
                        color: Colors.white,
                      )
                    : Text('${date.day}', style: const TextStyle(fontSize: 12)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.title,
    required this.subtitle,
    required this.complete,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final bool complete;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: complete
                  ? AppColors.yellow.withValues(alpha: .25)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              complete ? CupertinoIcons.rosette : CupertinoIcons.circle,
              color: complete ? AppColors.primary : AppColors.subtitle,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(subtitle),
          trailing: Text(
            complete ? 'Done' : 'In progress',
            style: TextStyle(
              color: complete ? AppColors.primary : AppColors.subtitle,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 72),
      ],
    );
  }
}

class _DeletedRow extends StatelessWidget {
  const _DeletedRow({
    required this.note,
    required this.isLast,
    required this.onTap,
  });

  final Note note;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(note.deletedAt ?? note.updatedAt);
    final remaining = (30 - elapsed.inDays).clamp(0, 30);
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          title: Text(
            note.title.isEmpty ? 'Untitled' : note.title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '${_shortDate(note.deletedAt ?? note.updatedAt)} · $remaining days remaining',
            style: const TextStyle(color: AppColors.red),
          ),
          trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
        ),
        if (!isLast) const Divider(height: 1, indent: 16),
      ],
    );
  }
}

class _SliverSectionTitle extends StatelessWidget {
  const _SliverSectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 11),
        child: Row(
          children: [
            Text(title, style: _eyebrowStyle),
            const Spacer(),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(color: AppColors.subtitle, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          if (trailing != null)
            Text(trailing!, style: const TextStyle(color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(value, style: _eyebrowStyle),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.subtitle),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: Color(0xFFF3EACB),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 38),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.subtitle, height: 1.4),
            ),
            const SizedBox(height: 22),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: AppColors.red,
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

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
              leading: const Icon(CupertinoIcons.trash, color: AppColors.red),
              title: const Text(
                'Delete Folder',
                style: TextStyle(color: AppColors.red),
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
              leading: const Icon(
                CupertinoIcons.arrow_counterclockwise,
                color: AppColors.primary,
              ),
              title: const Text('Recover Note'),
              onTap: () {
                Navigator.pop(context);
                controller.restoreNote(note);
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.trash, color: AppColors.red),
              title: const Text(
                'Delete Permanently',
                style: TextStyle(color: AppColors.red),
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
        decoration: const BoxDecoration(
          color: Color(0xFFF3EACB),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 21),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(CupertinoIcons.chevron_right, size: 15),
      onTap: onTap,
    );
  }
}

void _openMenuRoute(BuildContext context, String route) {
  Navigator.pop(context);
  Get.toNamed(route);
}

List<String> _extractTags(List<Note> notes) {
  final counts = <String, int>{};
  final expression = RegExp(r'#[a-zA-Z0-9_-]+');
  for (final note in notes) {
    for (final match in expression.allMatches(note.content)) {
      final tag = match.group(0)!.toLowerCase();
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final tags = entries.take(8).map((entry) => entry.key).toList();
  return tags.isEmpty
      ? ['#inspiration', '#work', '#personal', '#travel']
      : tags;
}

String _shortDate(DateTime date) {
  final now = DateTime.now();
  if (DateUtils.isSameDay(date, now)) return DateFormat.jm().format(date);
  if (DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))) {
    return 'Yesterday';
  }
  return DateFormat.MMMd().format(date);
}

int _wordCount(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
}

const _eyebrowStyle = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 12,
  letterSpacing: 1.25,
  fontWeight: FontWeight.w700,
);
