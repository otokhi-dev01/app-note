import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/folder_model.dart';
import '../../../data/models/note_model.dart';
import '../../../routes/note_navigation.dart';
import '../../../widgets/glass_widgets.dart';
import '../controllers/trash_controller.dart';

class TrashView extends GetView<TrashController> {
  const TrashView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // SliverAppBar with Dynamic Title Transition (Large to Small)
            SliverAppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              expandedHeight: 140.0,
              elevation: 0,
              automaticallyImplyLeading: false,
              centerTitle: true,
              systemOverlayStyle: theme.brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
              // Centered small title (visible when collapsed)
              title: LayoutBuilder(
                builder: (context, constraints) {
                  final double percentage =
                      (constraints.maxHeight - kToolbarHeight) /
                      (140.0 - kToolbarHeight);
                  final opacity = (1.0 - percentage).clamp(0.0, 1.0);

                  return Opacity(
                    opacity: opacity > 0.8 ? 1.0 : 0.0,
                    child: Text(
                      "Trash",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                  );
                },
              ),
              leading: Center(
                child: LiquidGlassContainer(
                  width: 44,
                  height: 44,
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
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              leadingWidth: 70,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Obx(
                    () => controller.isEditing.value
                        ? LiquidGlassContainer(
                            width: 44,
                            height: 44,
                            shape: GlassShape.circle,
                            showGlow: true,
                            thickness: 8,
                            opacity: 0.15,
                            blur: 10,
                            child: GestureDetector(
                              onTap: controller.toggleEditing,
                              child: Center(
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.primaryColor,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : LiquidGlassContainer(
                            height: 44,
                            borderRadius: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            showGlow: true,
                            thickness: 8,
                            opacity: 0.15,
                            blur: 10,
                            child: TextButton(
                              onPressed: controller.toggleEditing,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "Edit",
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
                title: LayoutBuilder(
                  builder: (context, constraints) {
                    final double percentage =
                        (constraints.maxHeight - kToolbarHeight) /
                        (140.0 - kToolbarHeight);
                    return Opacity(
                      opacity: percentage.clamp(0.0, 1.0),
                      child: Text(
                        "Trash",
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 27,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Obx(
                  () => Text(
                    "${controller.trashNotes.length + controller.trashFolders.length} Items",
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            ),

            Obx(() {
              if (controller.isLoading.value) {
                return SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: theme.primaryColor),
                  ),
                );
              }

              if (controller.trashNotes.isEmpty &&
                  controller.trashFolders.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      "No items in trash",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: GlassCard(
                    borderRadius: 30,
                    children: [
                      for (
                        int i = 0;
                        i < controller.trashFolders.length;
                        i++
                      ) ...[
                        _buildFolderTile(context, controller.trashFolders[i]),
                        const Divider(indent: 56, height: 1),
                      ],
                      for (
                        int i = 0;
                        i < controller.trashNotes.length;
                        i++
                      ) ...[
                        _buildNoteTile(context, controller.trashNotes[i]),
                        if (i < controller.trashNotes.length - 1)
                          const Divider(indent: 56, height: 1),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        bottomNavigationBar: Obx(
          () => controller.isEditing.value
              ? _buildEditBottomBar(context)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildFolderTile(BuildContext context, FolderModel folder) {
    final theme = Theme.of(context);
    return Obx(() {
      final isSelected = controller.selectedFolderIds.contains(folder.id);
      return ListTile(
        onTap: controller.isEditing.value
            ? () => controller.toggleSelectFolder(folder.id)
            : null,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.isEditing.value)
              _buildSelectionIndicator(context, isSelected),
            Icon(folder.icon, color: theme.primaryColor, size: 30),
          ],
        ),
        title: Text(
          folder.name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text("Folder", style: theme.textTheme.bodySmall),
      );
    });
  }

  Widget _buildNoteTile(BuildContext context, NoteModel note) {
    final theme = Theme.of(context);
    return Obx(() {
      final isSelected = controller.selectedNoteIds.contains(note.id);
      final isEditing = controller.isEditing.value;
      return ListTile(
        onTap: isEditing
            ? () => controller.toggleSelectNote(note.id)
            : () => NoteNavigation.toDetail(note),
        leading: isEditing
            ? _buildSelectionIndicator(context, isSelected)
            : null,
        title: Text(
          note.title.isEmpty ? "New Note" : note.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          DateFormat('MM/dd/yy').format(note.updatedAt ?? DateTime.now()),
          style: theme.textTheme.bodySmall,
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.outline,
          size: 20,
        ),
      );
    });
  }

  Widget _buildSelectionIndicator(BuildContext context, bool isSelected) {
    final theme = Theme.of(context);
    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? theme.colorScheme.onSurface : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: isSelected
          ? Icon(Icons.check, color: theme.colorScheme.surface, size: 14)
          : null,
    );
  }

  Widget _buildEditBottomBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Obx(() {
          final hasSelection = controller.selectedNoteIds.isNotEmpty || 
                             controller.selectedFolderIds.isNotEmpty;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _actionButton(
                context,
                hasSelection ? "Recover" : "Recover All",
                onTap: controller.recoverSelectedItems,
              ),
              _actionButton(
                context,
                hasSelection ? "Delete" : "Delete All",
                color: Colors.redAccent,
                onTap: controller.deletePermanently,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    String label, {
    Color? color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlassContainer(
        borderRadius: 25,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        thickness: 6,
        showGlow: true,
        child: Text(
          label,
          style: TextStyle(
            color: color ?? theme.colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
