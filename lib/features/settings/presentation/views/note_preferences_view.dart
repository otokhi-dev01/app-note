import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/settings/presentation/controllers/note_preferences_controller.dart';

class NotePreferencesView extends GetView<NotePreferencesController> {
  const NotePreferencesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
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
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            CustomGlassSliverAppBar(
              expandedHeight: 120,
              toolbarHeight: 56,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              centerTitle: true,
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
              title: Text(
                "Note Preferences",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
              largeTitlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
              largeTitle: Text(
                "Note Preferences",
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildSectionHeader(context, "Default View"),
                    const SizedBox(height: 12),
                    GlassCard(
                      borderRadius: 28,
                      children: [
                        _buildOption(
                          context,
                          title: "List",
                          icon: Icons.list_rounded,
                          isSelected: () => controller.viewMode.value == 'list',
                          onTap: () => controller.setViewMode('list'),
                        ),
                        const Divider(indent: 56, height: 1),
                        _buildOption(
                          context,
                          title: "Grid",
                          icon: Icons.grid_view_rounded,
                          isSelected: () =>
                              controller.viewMode.value == 'gallery',
                          onTap: () => controller.setViewMode('gallery'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, "Sort Notes By"),
                    const SizedBox(height: 12),
                    GlassCard(
                      borderRadius: 28,
                      children: [
                        _buildOption(
                          context,
                          title: "Date Edited",
                          icon: Icons.access_time_rounded,
                          isSelected: () => !controller.sortByName.value,
                          onTap: () => controller.setSortByName(false),
                        ),
                        const Divider(indent: 56, height: 1),
                        _buildOption(
                          context,
                          title: "Name",
                          icon: Icons.sort_by_alpha_rounded,
                          isSelected: () => controller.sortByName.value,
                          onTap: () => controller.setSortByName(true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, "Folders"),
                    const SizedBox(height: 12),
                    GlassCard(
                      borderRadius: 28,
                      children: [
                        Obx(
                          () => CustomGlassListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.calendar_view_day_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                            title: const Text(
                              "Group by Date",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: const Text(
                              "Off sorts folders manually, by name",
                            ),
                            trailing: Switch.adaptive(
                              value: controller.folderGroupByDate.value,
                              activeThumbColor: AppTheme.folderPink,
                              onChanged: controller.setFolderGroupByDate,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool Function() isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Obx(() {
      final selected = isSelected();
      return CustomGlassListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.folderPink.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: selected
                ? AppTheme.folderPink
                : theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        trailing: selected
            ? const Icon(Icons.check_circle_rounded, color: AppTheme.folderPink)
            : null,
      );
    });
  }
}
