import 'package:Note/app/modules/note/widgets/note_list_bottom_bars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/folder_model.dart';
import '../../../data/models/note_model.dart';
import '../../../widgets/glass_widgets.dart';
import '../controllers/note_controller.dart';
import '../../../theme/app_theme.dart';
import '../widgets/note_context_menu.dart';
import '../widgets/note_list_tile.dart';
import '../widgets/note_grid_tile.dart';

class NoteListView extends GetView<NoteController> {
  const NoteListView({super.key});

  @override
  Widget build(BuildContext context) {
    final FolderModel? folder = Get.arguments is FolderModel
        ? Get.arguments
        : null;
    final theme = Theme.of(context);
    final folderName = folder?.name ?? "All Notes";
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
                _buildAppBar(context, folderName),
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

  Widget _buildAppBar(BuildContext context, String title) {
    final theme = Theme.of(context);
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      pinned: true,
      expandedHeight: 140.0,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: true,
      systemOverlayStyle: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
      title: LayoutBuilder(
        builder: (context, constraints) {
          final double percentage =
              (constraints.maxHeight - kToolbarHeight) /
              (140.0 - kToolbarHeight);
          final opacity = (1.0 - percentage).clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity > 0.8 ? 1.0 : 0.0,
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          );
        },
      ),
      leading: Center(
        child: LiquidGlassContainer(
          width: 45,
          height: 45,
          shape: GlassShape.circle,
          showGlow: true,
          thickness: 8,
          refractiveIndex: 1.1,
          opacity: 0.15,
          blur: 10,
          child: IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              CupertinoIcons.chevron_left,
              color: theme.colorScheme.onSurface,
              size: 20,
              fontWeight: FontWeight.bold,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ),
      leadingWidth: 70,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Obx(() => _buildActionIcon(context)),
        ),

      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final double percentage =
                (constraints.maxHeight - kToolbarHeight) /
                (140.0 - kToolbarHeight);
            return Opacity(
              opacity: percentage.clamp(0.0, 1.0),
              child: Text(
                title,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionIcon(BuildContext context) {
    final theme = Theme.of(context);
    if (controller.isEditing.value) {
      return LiquidGlassContainer(
        width: 45,
        height: 45,
        shape: GlassShape.circle,
        showGlow: true,
        thickness: 8,
        opacity: 0.15,
        blur: 10,
        child: GestureDetector(
          onTap: controller.toggleEditing,
          child: Center(
              child: Icon(Icons.check, color: theme.colorScheme.onSurface, size: 20, fontWeight: FontWeight.bold),
            ),
          ),
      );
    }

    return GestureDetector(
      onTap: () => Get.dialog(
        NoteContextMenu(controller: controller),
        barrierColor: Colors.black.withValues(alpha: 0.1),
      ),
      child: LiquidGlassContainer(
        width: 45,
        height: 45,
        shape: GlassShape.circle,
        showGlow: true,
        thickness: 8,
        opacity: 0.15,
        blur: 10,
        child: Center(
          child: Icon(
            Icons.more_horiz,
            color: theme.colorScheme.onSurface,
            size: 20,
            fontWeight: FontWeight.bold,
          ),
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
                  "No Notes",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
                child: Text("Pinned", style: theme.textTheme.titleLarge),
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
                  child: Text("Notes", style: theme.textTheme.titleLarge),
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
                  child: const Text("Retry"),
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
                  "No Notes",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
          ? _groupNotesByDate(otherNotes) 
          : {"Notes": otherNotes};

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
                      child: Text("Pinned", style: theme.textTheme.titleLarge),
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
    Map<String, List<NoteModel>> groupedNotes,
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

  Map<String, List<NoteModel>> _groupNotesByDate(List<NoteModel> notes) {
    Map<String, List<NoteModel>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sevenDaysAgo = today.subtract(const Duration(days: 7));

    for (var note in notes) {
      final date = note.updatedAt ?? now;
      final noteDate = DateTime(date.year, date.month, date.day);

      String key;
      if (noteDate == today) {
        key = "Today";
      } else if (noteDate == yesterday) {
        key = "Yesterday";
      } else if (noteDate.isAfter(sevenDaysAgo)) {
        key = "Previous 7 Days";
      } else {
        key = DateFormat('MMMM').format(date);
      }

      if (!groups.containsKey(key)) groups[key] = [];
      groups[key]!.add(note);
    }
    return groups;
  }
}
