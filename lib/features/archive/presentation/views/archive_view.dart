import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/note/presentation/controllers/note_controller.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/features/archive/presentation/widgets/archive_note_tile.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/utils/note_grouping.dart';

class ArchiveView extends GetView<NoteController> {
  const ArchiveView({super.key});

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
        body: RefreshIndicator(
          onRefresh: () => controller.fetchNotes(refresh: true),
          color: theme.primaryColor,
          backgroundColor: theme.scaffoldBackgroundColor,
          edgeOffset: 140,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(context),
              _buildArchiveHeader(context),
              _buildArchiveList(context),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
        bottomNavigationBar: Obx(() {
          if (controller.isEditing.value) {
            return _buildEditBottomBar(context);
          }
          return const SizedBox.shrink();
        }),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return CustomGlassSliverAppBar(
      expandedHeight: 140,
      toolbarHeight: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      centerTitle: true,
      title: Text(
        "note_list_archive_title".tr,
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
        ),
      ),
      actions: [
        Obx(
          () => controller.isEditing.value
              ? CustomGlassButton(
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
                  ),
                )
              : CustomGlassButton(
                  onPressed: controller.toggleEditing,
                  height: 44,
                  borderRadius: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  blur: 10,
                  opacity: 0.15,
                  thickness: 8,
                  child: Text(
                    "note_list_edit".tr,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ],
      largeTitleAlignment: Alignment.bottomCenter,
      largeTitlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
      largeTitle: Text(
        "note_list_archive_title".tr,
        style: theme.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 34,
        ),
      ),
    );
  }

  Widget _buildArchiveHeader(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (controller.archivedNotes.length == 1
                        ? 'note_list_archived_count_one'
                        : 'note_list_archived_count_other')
                    .trParams({'count': '${controller.archivedNotes.length}'}),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "note_list_archive_description".tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArchiveList(BuildContext context) {
    Theme.of(context);
    return Obx(() {
      if (controller.isLoading.value) {
        return const SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.folderPink),
          ),
        );
      }

      if (controller.archivedNotes.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.archivebox,
                  size: 60,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  "note_list_no_archived_notes".tr,
                  style: const TextStyle(color: Colors.grey, fontSize: 18),
                ),
              ],
            ),
          ),
        );
      }

      final pinnedArchived = controller.pinnedArchivedNotes;
      final otherArchived = controller.otherArchivedNotes;
      final groupedNotes = NoteGrouping.byDate(otherArchived);

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (pinnedArchived.isNotEmpty) {
                if (index == 0) {
                  return _buildSection(context, "Pinned", pinnedArchived);
                }
                final groupIndex = index - 1;
                if (groupIndex < groupedNotes.length) {
                  final section = groupedNotes.keys.elementAt(groupIndex);
                  return _buildSection(
                    context,
                    section,
                    groupedNotes[section]!,
                  );
                }
              } else {
                if (index < groupedNotes.length) {
                  final section = groupedNotes.keys.elementAt(index);
                  return _buildSection(
                    context,
                    section,
                    groupedNotes[section]!,
                  );
                }
              }
              return null;
            },
            childCount:
                (pinnedArchived.isNotEmpty ? 1 : 0) + groupedNotes.length,
          ),
        ),
      );
    });
  }

  Widget _buildSection(BuildContext context, String title, List<Note> notes) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 16, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
        GlassCard(
          borderRadius: 28,
          children: [
            for (int i = 0; i < notes.length; i++) ...[
              ArchiveNoteTile(note: notes[i], controller: controller),
              if (i < notes.length - 1)
                const Divider(indent: 20, height: 1, thickness: 0.5),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildEditBottomBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _actionButton(
                context,
                "note_list_delete".tr,
                color: Colors.redAccent,
                onTap: () => controller.deleteSelectedNotes(0),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _actionButton(
                context,
                "note_list_unarchive".tr,
                onTap: () {
                  // Implementation for unarchiving selected notes
                  AppSnackbar.info(
                    'note_list_info_title'.tr,
                    'note_list_unarchive_coming_soon'.tr,
                  );
                },
              ),
            ),
          ],
        ),
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
    return CustomGlassButton(
      onPressed: onTap,
      height: 48,
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      blur: 10,
      opacity: 0.15,
      thickness: 8,
      child: Text(
        label,
        style: TextStyle(
          color: color ?? theme.colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
