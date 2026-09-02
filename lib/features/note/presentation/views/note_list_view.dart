import 'package:Note/features/note/presentation/widgets/note_list_bottom_bars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/note/presentation/controllers/note_controller.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/features/note/presentation/widgets/note_context_menu.dart';
import 'package:Note/features/note/presentation/widgets/note_list_tile.dart';
import 'package:Note/features/note/presentation/widgets/note_grid_tile.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/features/folder/presentation/widgets/folder_create_modal.dart';
import 'package:Note/features/folder/presentation/widgets/folder_glass_icon.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/core/utils/note_grouping.dart';

class NoteListView extends GetView<NoteController> {
  final Folder? folder;

  const NoteListView({super.key, this.folder});

  @override
  Widget build(BuildContext context) {
    final routeFolder =
        folder ?? (Get.arguments is Folder ? Get.arguments : null);
    final theme = Theme.of(context);
    final folderName = routeFolder != null
        ? FolderAppearance.displayName(routeFolder.name)
        : "note_list_all_notes".tr;
    final int folderId = routeFolder?.id ?? 0;
    final isFolderContent = routeFolder != null && folderId > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        body: RefreshIndicator(
          onRefresh: () =>
              controller.fetchNotes(folderId: routeFolder?.id, refresh: true),
          color: theme.primaryColor,
          backgroundColor: theme.scaffoldBackgroundColor,
          edgeOffset: MediaQuery.paddingOf(context).top + 52,
          child: Obx(
            () => CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(
                  context,
                  folderName,
                  folderId,
                  isFolderContent: isFolderContent,
                ),
                if (isFolderContent) ...[
                  _buildFolderHeader(context, routeFolder),
                  _buildSubfolderSection(context, routeFolder),
                ],
                if (controller.viewMode.value == "gallery")
                  _buildNoteGrid(context, folderId)
                else
                  _buildNoteList(
                    context,
                    folderId,
                    isFolderContent: isFolderContent,
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Obx(() {
          if (controller.isEditing.value) {
            return NoteListEditBar(folderId: folderId, controller: controller);
          }
          return NoteListBottomBar(folderId: folderId, controller: controller);
        }),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    String title,
    int folderId, {
    required bool isFolderContent,
  }) {
    final theme = Theme.of(context);
    return AppScreenSliverAppBar(
      centerTitle: true,
      title: isFolderContent ? null : title,
      leading: CustomGlassButton(
        onPressed: () => Get.back(),
        width: 44,
        height: 44,
        shape: GlassShape.circle,
        blur: 10,
        opacity: 0.15,
        thickness: 8,
        padding: EdgeInsets.zero,
        child: Icon(
          CupertinoIcons.chevron_left,
          color: theme.colorScheme.onSurface,
          size: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [Obx(() => _buildActionIcon(context))],
    );
  }

  void _createFolder(int folderId) {
    final folderController = Get.find<FolderController>();
    Get.to(
      () => FolderCreateModal(
        controller: folderController,
        parentId: folderId == 0 ? null : folderId,
        // This modal is nested inside the folder-content route. Return here
        // after saving instead of unwinding all the way to the root folders.
        onDone: () => Get.back(),
      ),
      fullscreenDialog: true,
      transition: Transition.cupertino,
    );
  }

  Widget _buildActionIcon(BuildContext context) {
    final theme = Theme.of(context);
    if (controller.isEditing.value) {
      return CustomGlassButton(
        onPressed: controller.toggleEditing,
        width: 44,
        height: 44,
        shape: GlassShape.circle,
        blur: 10,
        opacity: 0.15,
        thickness: 8,
        padding: EdgeInsets.zero,
        child: Icon(
          Icons.check,
          color: theme.colorScheme.onSurface,
          size: 24,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return NoteContextMenu(
      controller: controller,
      onAddFolder: () => _createFolder(_currentFolderId),
      triggerBuilder: (context, toggleMenu) => CustomGlassButton(
        onPressed: toggleMenu,
        semanticLabel: "note_list_more_options".tr,
        width: 44,
        height: 44,
        shape: GlassShape.circle,
        blur: 10,
        opacity: 0.15,
        thickness: 8,
        padding: EdgeInsets.zero,
        child: Icon(
          Icons.more_horiz,
          color: theme.colorScheme.onSurface,
          size: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  int get _currentFolderId {
    final routeFolder =
        folder ?? (Get.arguments is Folder ? Get.arguments : null);
    return routeFolder?.id ?? 0;
  }

  Widget _buildFolderHeader(BuildContext context, Folder currentFolder) {
    final theme = Theme.of(context);
    final folderController = Get.find<FolderController>();

    return SliverToBoxAdapter(
      child: Obx(() {
        final latestFolder =
            folderController.folders.firstWhereOrNull(
              (candidate) => candidate.id == currentFolder.id,
            ) ??
            currentFolder;
        final subfolderCount = _subfoldersOf(
          latestFolder,
          folderController,
        ).length;
        final noteCount = controller.isLoading.value
            ? latestFolder.noteCount
            : controller.notes.length;
        final noteLabel =
            (noteCount == 1
                    ? 'note_list_note_count_one'
                    : 'note_list_note_count_other')
                .trParams({'count': '$noteCount'});
        final folderLabel =
            (subfolderCount == 1
                    ? 'note_list_folder_count_one'
                    : 'note_list_folder_count_other')
                .trParams({'count': '$subfolderCount'});

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                latestFolder.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.1,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$noteLabel  ·  $folderLabel',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.58,
                  ),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSubfolderSection(BuildContext context, Folder currentFolder) {
    final theme = Theme.of(context);
    final folderController = Get.find<FolderController>();

    return Obx(() {
      final children = _subfoldersOf(currentFolder, folderController);
      if (children.isEmpty) return const SliverToBoxAdapter();
      final isExpanded = folderController.isFolderExpanded(currentFolder.id);

      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    folderController.toggleFolderExpanded(currentFolder.id),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'note_list_folders'.tr,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? CupertinoIcons.chevron_down
                            : CupertinoIcons.chevron_right,
                        color: theme.primaryColor,
                        size: 19,
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                GlassCard(
                  borderRadius: 30,
                  children: [
                    for (int index = 0; index < children.length; index++) ...[
                      _FolderContentTile(
                        folder: children[index],
                        onTap: () =>
                            _openSubfolder(children[index], currentFolder),
                      ),
                      if (index < children.length - 1)
                        const Divider(indent: 64, height: 1, thickness: 0.5),
                    ],
                  ],
                ),
            ],
          ),
        ),
      );
    });
  }

  List<Folder> _subfoldersOf(Folder parent, FolderController folderController) {
    final byId = <int, Folder>{
      for (final child in parent.subFolders) child.id: child,
      for (final child in folderController.folders)
        if (child.parentId == parent.id) child.id: child,
    };
    final children = byId.values.toList();
    children.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      return order != 0
          ? order
          : a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return children;
  }

  Future<void> _openSubfolder(Folder child, Folder parent) async {
    if (controller.isEditing.value) controller.toggleEditing();

    final route = Get.to(
      () => NoteListView(folder: child),
      routeName: Routes.NOTE_LIST,
      arguments: child,
      preventDuplicates: false,
      transition: Transition.cupertino,
    );

    // The nested screens intentionally share this list controller. Load the
    // child immediately, then restore the parent's notes when the child pops.
    await controller.fetchNotes(folderId: child.id);
    await route;
    await controller.fetchNotes(folderId: parent.id, refresh: true);
  }

  Widget _buildNoteGrid(BuildContext context, int folderId) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.isLoading.value) {
        return SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(color: theme.primaryColor),
          ),
        );
      }

      if (controller.notes.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.doc_text,
                  size: 60,
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  "note_list_empty_title".tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final pinnedNotes = controller.pinnedNotes;
      final otherNotes = controller.otherNotes;

      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pinnedNotes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                child: Text(
                  "note_list_pinned".tr,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: pinnedNotes.length,
                itemBuilder: (context, index) {
                  return NoteGridTile(
                    note: pinnedNotes[index],
                    folderId: folderId,
                    controller: controller,
                  );
                },
              ),
              if (otherNotes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                  child: Text(
                    "note_list_notes".tr,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
            ],
            if (otherNotes.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: otherNotes.length,
                itemBuilder: (context, index) {
                  return NoteGridTile(
                    note: otherNotes[index],
                    folderId: folderId,
                    controller: controller,
                  );
                },
              ),
          ],
        ),
      );
    });
  }

  Widget _buildNoteList(
    BuildContext context,
    int folderId, {
    required bool isFolderContent,
  }) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.isLoading.value) {
        return SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(color: theme.primaryColor),
          ),
        );
      }

      if (controller.hasError.value) {
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 64,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => controller.fetchNotes(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                  ),
                  child: Text("note_list_retry".tr),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.notes.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.doc_text,
                  size: 60,
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  "note_list_empty_title".tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final pinnedNotes = controller.pinnedNotes;
      final otherNotes = controller.otherNotes;
      final groupedNotes = controller.isGroupedByDate.value
          ? NoteGrouping.byDate(otherNotes)
          : {"note_list_notes".tr: otherNotes};

      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (pinnedNotes.isNotEmpty) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Text(
                        "note_list_pinned".tr,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    GlassCard(
                      borderRadius: 30,
                      children: [
                        for (int i = 0; i < pinnedNotes.length; i++) ...[
                          NoteListTile(
                            note: pinnedNotes[i],
                            folderId: folderId,
                            controller: controller,
                            showChevron: !isFolderContent,
                          ),
                          if (i < pinnedNotes.length - 1)
                            const Divider(indent: 56, height: 1),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }

            final groupIndex = index - 1;
            if (groupIndex < groupedNotes.length) {
              return _buildDateGroup(
                context,
                groupedNotes,
                groupIndex,
                folderId,
                isFolderContent: isFolderContent,
              );
            }
          } else {
            if (index < groupedNotes.length) {
              return _buildDateGroup(
                context,
                groupedNotes,
                index,
                folderId,
                isFolderContent: isFolderContent,
              );
            }
          }
          return null;
        }, childCount: (pinnedNotes.isNotEmpty ? 1 : 0) + groupedNotes.length),
      );
    });
  }

  Widget _buildDateGroup(
    BuildContext context,
    Map<String, List<Note>> groupedNotes,
    int index,
    int folderId, {
    required bool isFolderContent,
  }) {
    final theme = Theme.of(context);
    final section = groupedNotes.keys.elementAt(index);
    final sectionNotes = groupedNotes[section]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(section, style: theme.textTheme.titleLarge),
          ),
          GlassCard(
            borderRadius: 30,
            children: [
              for (int i = 0; i < sectionNotes.length; i++) ...[
                NoteListTile(
                  note: sectionNotes[i],
                  folderId: folderId,
                  controller: controller,
                  showChevron: !isFolderContent,
                ),
                if (i < sectionNotes.length - 1)
                  const Divider(indent: 56, height: 1),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FolderContentTile extends StatelessWidget {
  final Folder folder;
  final VoidCallback onTap;

  const _FolderContentTile({required this.folder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomGlassListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: FolderGlassIcon(
        color: folder.color,
        child: FolderGlyph(folder: folder, size: 22),
      ),
      title: Text(
        folder.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${folder.noteCount}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 5),
          Icon(
            CupertinoIcons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
            size: 18,
          ),
        ],
      ),
    );
  }
}
