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
import 'package:Note/core/utils/note_grouping.dart';

class NoteListView extends GetView<NoteController> {
  const NoteListView({super.key});

  @override
  Widget build(BuildContext context) {
    final Folder? folder = Get.arguments is Folder ? Get.arguments : null;
    final theme = Theme.of(context);
    final folderName = folder != null
        ? FolderAppearance.displayName(folder.name)
        : "note_list_all_notes".tr;
    final int folderId = folder?.id ?? 0;

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
              controller.fetchNotes(folderId: folder?.id, refresh: true),
          color: theme.primaryColor,
          backgroundColor: theme.scaffoldBackgroundColor,
          edgeOffset: 140,
          child: Obx(
            () => CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(context, folderName, folderId),
                if (controller.viewMode.value == "gallery")
                  _buildNoteGrid(context, folderId)
                else
                  _buildNoteList(context, folderId),
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

  Widget _buildAppBar(BuildContext context, String title, int folderId) {
    final theme = Theme.of(context);
    return CustomGlassSliverAppBar(
      expandedHeight: 140,
      toolbarHeight: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      centerTitle: true,
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
      ),
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
      actions: [
        CustomGlassButton(
          onPressed: () => _createFolder(folderId),
          semanticLabel: "note_list_add_folder".tr,
          width: 44,
          height: 44,
          shape: GlassShape.circle,
          blur: 10,
          opacity: 0.15,
          thickness: 8,
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.folder_badge_plus,
            color: theme.primaryColor,
            size: 22,
          ),
        ),
        Obx(() => _buildActionIcon(context)),
      ],
      largeTitlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 5),
      largeTitle: Text(
        title,
        style: theme.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 34,
        ),
      ),
    );
  }

  /// Creates a subfolder of the folder currently being viewed ("All Notes"
  /// creates at the top level instead, since it has no real folder id).
  void _createFolder(int folderId) {
    Get.to(
      () => FolderCreateModal(
        controller: Get.find<FolderController>(),
        parentId: folderId == 0 ? null : folderId,
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

    // The button itself morphs into the menu, so it hands its tap to
    // NoteContextMenu rather than opening anything of its own.
    return NoteContextMenu(
      controller: controller,
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
                child: Text("note_list_pinned".tr, style: theme.textTheme.titleLarge),
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
                  child: Text("note_list_notes".tr, style: theme.textTheme.titleLarge),
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

  Widget _buildNoteList(BuildContext context, int folderId) {
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
          // If there are pinned notes, the first item is the Pinned section
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
                      child: Text("note_list_pinned".tr, style: theme.textTheme.titleLarge),
                    ),
                    GlassCard(
                      borderRadius: 30,
                      children: [
                        for (int i = 0; i < pinnedNotes.length; i++) ...[
                          NoteListTile(
                            note: pinnedNotes[i],
                            folderId: folderId,
                            controller: controller,
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

            // Adjust index for groups
            final groupIndex = index - 1;
            if (groupIndex < groupedNotes.length) {
              return _buildDateGroup(
                context,
                groupedNotes,
                groupIndex,
                folderId,
              );
            }
          } else {
            // No pinned notes, just groups
            if (index < groupedNotes.length) {
              return _buildDateGroup(context, groupedNotes, index, folderId);
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
    int folderId,
  ) {
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
