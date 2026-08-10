import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/note_model.dart';
import '../../../routes/app_pages.dart';
import '../../../routes/note_navigation.dart';
import '../../../widgets/glass_widgets.dart';
import '../controllers/pinned_controller.dart';

class PinnedView extends GetView<PinnedController> {
  const PinnedView({super.key});

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
              title: LayoutBuilder(
                builder: (context, constraints) {
                  final double percentage =
                      (constraints.maxHeight - kToolbarHeight) /
                      (140.0 - kToolbarHeight);
                  final opacity = (1.0 - percentage).clamp(0.0, 1.0);

                  return Opacity(
                    opacity: opacity > 0.8 ? 1.0 : 0.0,
                    child: Text(
                      "Pinned Notes",
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
                        "Pinned Notes",
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
                  () => Text(
                    '${controller.pinnedNotes.length} Notes',
                    style: theme.textTheme.bodyMedium,
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

              if (controller.pinnedNotes.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.push_pin_outlined,
                          size: 60,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No Pinned Notes",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
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
                    borderRadius: 30,
                    children: [
                      for (
                        int i = 0;
                        i < controller.pinnedNotes.length;
                        i++
                      ) ...[
                        _buildNoteTile(context, controller.pinnedNotes[i]),
                        if (i < controller.pinnedNotes.length - 1)
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

  Widget _buildNoteTile(BuildContext context, NoteModel note) {
    final theme = Theme.of(context);
    final attachmentCount = note.content.whereType<AttachmentBlock>().length;
    return Obx(() {
      final isSelected = controller.selectedNoteIds.contains(note.id);
      final isEditing = controller.isEditing.value;
      return ListTile(
        onTap: isEditing
            ? () => controller.toggleSelectNote(note.id)
            : () => NoteNavigation.toDetail(note),
        leading: isEditing
            ? _buildSelectionIndicator(context, isSelected)
            : Icon(Icons.push_pin, color: theme.primaryColor, size: 24),
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
                    ],
                  ),
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
          final hasSelection = controller.selectedNoteIds.isNotEmpty;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionButton(
                context,
                hasSelection ? "Unpin Selected" : "Unpin All",
                onTap: controller.unpinSelectedNotes,
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
