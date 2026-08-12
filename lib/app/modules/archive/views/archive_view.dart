import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/note_model.dart';
import '../../../widgets/glass_widgets.dart';
import '../../note/controllers/note_controller.dart';
import '../../../theme/app_theme.dart';
import '../widgets/archive_note_tile.dart';

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
    return SliverAppBar(
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
      title: LayoutBuilder(
        builder: (context, constraints) {
          final double percentage =
              (constraints.maxHeight - kToolbarHeight) /
              (140.0 - kToolbarHeight);
          final opacity = (1.0 - percentage).clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity > 0.8 ? 1.0 : 0.0,
            child: Text(
              "Archive",
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
                    height: 36,
                    borderRadius: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    showGlow: true,
                    thickness: 8,
                    opacity: 0.15,
                    blur: 10,
                    child: TextButton(
                      onPressed: controller.toggleEditing,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        "Edit",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
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
                "Archive",
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 34,
                ),
              ),
            );
          },
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
                '${controller.archivedNotes.length} ${controller.archivedNotes.length == 1 ? 'Note' : 'Notes'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Archived notes are kept separate from your main notes list. You can restore them at any time.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.isLoading.value) {
        return const SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.folderPink),
          ),
        );
      }

      if (controller.archivedNotes.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.archivebox,
                  size: 60,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  "No Archived Notes",
                  style: TextStyle(color: Colors.grey, fontSize: 18),
                ),
              ],
            ),
          ),
        );
      }

      final pinnedArchived = controller.pinnedArchivedNotes;
      final otherArchived = controller.otherArchivedNotes;
      final groupedNotes = _groupNotesByDate(otherArchived);

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
                  return _buildSection(context, section, groupedNotes[section]!);
                }
              } else {
                if (index < groupedNotes.length) {
                  final section = groupedNotes.keys.elementAt(index);
                  return _buildSection(context, section, groupedNotes[section]!);
                }
              }
              return null;
            },
            childCount: (pinnedArchived.isNotEmpty ? 1 : 0) + groupedNotes.length,
          ),
        ),
      );
    });
  }

  Widget _buildSection(BuildContext context, String title, List<NoteModel> notes) {
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
              ArchiveNoteTile(
                note: notes[i],
                controller: controller,
              ),
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _actionButton(
              context,
              "Delete",
              color: Colors.redAccent,
              onTap: () => controller.deleteSelectedNotes(0),
            ),
            _actionButton(
              context,
              "Unarchive",
              onTap: () {
                // Implementation for unarchiving selected notes
                Get.snackbar("Info", "Unarchive functionality coming soon");
              },
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
