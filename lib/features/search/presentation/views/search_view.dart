import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' hide GlassCard;

import 'package:Note/routes/app_pages.dart';
import 'package:Note/routes/note_navigation.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/search/presentation/controllers/search_controller.dart'
    as sc;
import 'package:Note/core/theme/app_colors.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/features/note/domain/entities/note.dart';

class SearchView extends GetView<sc.SearchController> {
  const SearchView({super.key});

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
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              /// Main content
              Column(
                children: [
                  _buildTopBar(context),

                  Expanded(
                    child: Obx(() {
                      if (controller.isSearching.value) {
                        return _buildSearchResults(context);
                      }

                      return _buildSuggestedSection(context);
                    }),
                  ),
                ],
              ),

              /// Floating Bottom Search Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomSearchBar(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          /// Back glass button
          CustomGlassButton(
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

          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Search',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
          ),

          /// Used to balance the back button
          const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }

  // ============================================================
  // SUGGESTED SECTION
  // ============================================================

  Widget _buildSuggestedSection(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Suggested title
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Suggested',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),

          /// Suggested glass container
          CustomGlassContainer(
            width: double.infinity,
            borderRadius: 30,
            blur: 35,
            opacity: 0.20,
            thickness: 20,
            showGlow: true,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < controller.suggestions.length; i++) ...[
                    _buildSuggestionTile(
                      context,
                      controller.suggestions[i]['title'] as String,
                      controller.suggestions[i]['icon'] as IconData,
                    ),

                    if (i < controller.suggestions.length - 1)
                      Divider(
                        indent: 56,
                        height: 1,
                        color: theme.dividerColor.withValues(alpha: 0.1),
                      ),
                  ],
                ],
              ),
            ),
          ),

          /// Space for bottom search bar
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // ============================================================
  // SUGGESTION TILE
  // ============================================================

  Widget _buildSuggestionTile(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return GlassListTile(
      onTap: () {
        controller.applyFilter(title);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),

      /// Icon container
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.folderYellow.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.folderYellow, size: 20),
      ),

      /// Title
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: AppColors.of(context).primaryText,
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH RESULTS
  // ============================================================

  Widget _buildSearchResults(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      /// No search result
      if (controller.noteResults.isEmpty && controller.folderResults.isEmpty) {
        return Center(
          child: Text(
            'No results found',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =====================================================
          // FOLDERS
          // =====================================================
          if (controller.folderResults.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Text('Folders', style: theme.textTheme.titleLarge),
            ),

            GlassCard(
              borderRadius: 30,
              children: [
                for (int i = 0; i < controller.folderResults.length; i++) ...[
                  GlassListTile(
                    onTap: () {
                      Get.toNamed(
                        Routes.NOTE_LIST,
                        arguments: controller.folderResults[i],
                      );
                    },
                    leading: Icon(
                      controller.folderResults[i].icon,
                      color: theme.primaryColor,
                    ),
                    title: Text(
                      controller.folderResults[i].name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: GlassListTile.chevron,
                  ),

                  if (i < controller.folderResults.length - 1)
                    Divider(
                      indent: 56,
                      height: 1,
                      color: theme.dividerColor.withValues(alpha: 0.1),
                    ),
                ],
              ],
            ),

            const SizedBox(height: 24),
          ],

          // =====================================================
          // NOTES
          // =====================================================
          if (controller.noteResults.isNotEmpty) ...[
            // ---------------------------------------------------
            // PINNED NOTES
            // ---------------------------------------------------
            if (controller.pinnedNoteResults.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text('Pinned Notes', style: theme.textTheme.titleLarge),
              ),

              GlassCard(
                borderRadius: 30,
                children: [
                  for (
                    int i = 0;
                    i < controller.pinnedNoteResults.length;
                    i++
                  ) ...[
                    _buildNoteTile(context, controller.pinnedNoteResults[i]),

                    if (i < controller.pinnedNoteResults.length - 1)
                      const Divider(indent: 16, height: 1),
                  ],
                ],
              ),

              const SizedBox(height: 24),
            ],

            // ---------------------------------------------------
            // OTHER NOTES
            // ---------------------------------------------------
            if (controller.otherNoteResults.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text('Notes', style: theme.textTheme.titleLarge),
              ),

              GlassCard(
                borderRadius: 30,
                children: [
                  for (
                    int i = 0;
                    i < controller.otherNoteResults.length;
                    i++
                  ) ...[
                    _buildNoteTile(context, controller.otherNoteResults[i]),

                    if (i < controller.otherNoteResults.length - 1)
                      const Divider(indent: 16, height: 1),
                  ],
                ],
              ),
            ],
          ],

          /// Space for floating search bar
          const SizedBox(height: 120),
        ],
      );
    });
  }

  // ============================================================
  // NOTE TILE
  // ============================================================

  Widget _buildNoteTile(BuildContext context, Note note) {
    final theme = Theme.of(context);

    return GlassListTile(
      onTap: () {
        NoteNavigation.toDetail(note);
      },
      title: Text(
        note.title.isEmpty ? 'New Note' : note.title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      trailing: GlassListTile.chevron,
    );
  }

  // ============================================================
  // BOTTOM BAR
  // ============================================================

  Widget _buildBottomBar(BuildContext context) {
    final theme = Theme.of(context);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset > 0 ? 10 : 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ===================================================
            // SEARCH GLASS CONTAINER
            // ===================================================
            Expanded(
              child: CustomGlassContainer(
                /// Change the search bar height here
                height: 50,

                showGlow: true,
                thickness: 20,
                refractiveIndex: 2,
                opacity: 0.20,

                padding: const EdgeInsets.symmetric(horizontal: 18),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// Search icon
                    Icon(
                      CupertinoIcons.search,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                      size: 22,
                    ),

                    const SizedBox(width: 10),

                    /// Search field
                    Expanded(
                      child: TextField(
                        controller: controller.searchController,
                        onChanged: controller.onSearchChanged,
                        autofocus: true,
                        cursorColor: AppTheme.folderYellow,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 17,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                            fontSize: 17,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    /// Microphone
                    Icon(
                      CupertinoIcons.mic_fill,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ===================================================
            // CLOSE BUTTON
            // ===================================================
            CustomGlassButton(
              onPressed: () {
                if (controller.isSearching.value) {
                  controller.clearSearch();
                } else {
                  Get.back();
                }
              },
              width: 50,
              height: 50,
              shape: GlassShape.circle,
              blur: 10,
              opacity: 0.15,
              thickness: 8,
              padding: EdgeInsets.zero,
              child: Icon(
                CupertinoIcons.xmark,
                color: AppTheme.folderPink,
                size: 27,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM SEARCH BAR
  // ============================================================

  Widget _buildBottomSearchBar(BuildContext context) {
    return _buildBottomBar(context);
  }
}
