import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/folder_model.dart';
import '../../../data/models/note_model.dart';
import '../../../routes/app_pages.dart';
import '../../../routes/note_navigation.dart';
import '../../../widgets/glass_widgets.dart';
import '../controllers/recently_deleted_controller.dart';
import '../widgets/slidable_note_tile.dart';

class RecentlyDeletedView extends GetView<RecentlyDeletedController> {
  const RecentlyDeletedView({super.key});

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
        extendBody: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // SliverAppBar with Dynamic iOS Transition
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
                      "Recently Deleted",
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
                  blur: 10, // Crisper glass icon
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(
                      CupertinoIcons.chevron_left,
                      color: theme.colorScheme.onSurface,
                      size: 28,
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
                        "Recently Deleted",
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${controller.deletedNotes.length + controller.deletedFolders.length} Items',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Notes are available here for 30 days. After that time, notes will be permanently deleted. This may take up to 40 days.",
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Main Items Container
            Obx(() {
              if (controller.isLoading.value) {
                return SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: theme.primaryColor),
                  ),
                );
              }

              final totalItems =
                  controller.deletedNotes.length +
                  controller.deletedFolders.length;

              if (totalItems == 0) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.delete,
                          size: 60,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No Deleted Items",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: controller.fetchDeletedItems,
                          child: const Text("Check for updates"),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                sliver: SliverToBoxAdapter(
                  child: GlassCard(
                    borderRadius: 20,
                    children: [
                      // Render Folders
                      for (
                        int i = 0;
                        i < controller.deletedFolders.length;
                        i++
                      ) ...[
                        _buildFolderTile(context, controller.deletedFolders[i]),
                        if (i < controller.deletedFolders.length - 1 ||
                            controller.deletedNotes.isNotEmpty)
                          const Divider(indent: 56, height: 1),
                      ],
                      // Render Notes
                      for (
                        int i = 0;
                        i < controller.deletedNotes.length;
                        i++
                      ) ...[
                        _buildNoteTile(context, controller.deletedNotes[i]),
                        if (i < controller.deletedNotes.length - 1)
                          const Divider(indent: 56, height: 1),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SliverToBoxAdapter(child: SizedBox(height: 112)),
          ],
        ),
        bottomNavigationBar: Obx(
          () => controller.isEditing.value
              ? _buildEditBottomBar(context)
              : _buildSearchBottomBar(context),
        ),
      ),
    );
  }

  Widget _buildFolderTile(BuildContext context, FolderModel folder) {
    final theme = Theme.of(context);
    return SlidableNoteTile(
      onMove: () => controller.recoverItem(folderId: folder.id),
      onDelete: () => controller.deleteItemPermanently(
        folderId: folder.id,
        name: folder.name,
      ),
      child: Obx(() {
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
      }),
    );
  }

  Widget _buildNoteTile(BuildContext context, NoteModel note) {
    final theme = Theme.of(context);
    final attachmentCount = note.content.whereType<AttachmentBlock>().length;
    return SlidableNoteTile(
      onMove: () => controller.recoverItem(noteId: note.id),
      onDelete: () =>
          controller.deleteItemPermanently(noteId: note.id, name: note.title),
      child: Obx(() {
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
            "${_formatDate(note.updatedAt)}  ${attachmentCount > 0 ? '$attachmentCount attachments' : _getContentSnippet(note)}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.outline,
            size: 20,
          ),
        );
      }),
    );
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

  Widget _buildSearchBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Get.toNamed(Routes.SEARCH),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: theme.brightness == Brightness.dark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Search",
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.mic,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            LiquidGlassContainer(
              width: 50,
              height: 50,
              shape: GlassShape.circle,
              showGlow: true,
              thickness: 10,
              refractiveIndex: 1.3,
              opacity: 0.15, // Standard glass icon opacity
              child: IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.open_in_new,
                  color: theme.colorScheme.onSurface,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
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
                onTap: controller.deletePermanentlySelectedItems,
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

  String _formatDate(DateTime? date) {
    if (date == null) return "";
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day)
      return DateFormat('HH:mm').format(date);
    return DateFormat('MM/dd/yy').format(date);
  }

  String _getContentSnippet(NoteModel note) {
    final textBlock =
        note.content.firstWhereOrNull((b) => b is TextBlock) as TextBlock?;
    return textBlock?.text.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
  }
}
