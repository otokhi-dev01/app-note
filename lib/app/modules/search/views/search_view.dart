import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../routes/note_navigation.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_widgets.dart';
import '../controllers/search_controller.dart' as sc;

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
              // Floating Bottom Search Bar
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

  Widget _buildTopBar(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          LiquidGlassContainer(
            width: 44,
            height: 44,
            shape: GlassShape.circle,
            showGlow: true,
            thickness: 8,
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
          Text(
            "Search",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
          const SizedBox(width: 44), // Spacer to balance leading
        ],
      ),
    );
  }

  Widget _buildSuggestedSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              "Suggested",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          Material(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(
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
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 100), // Space for floating search bar
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      onTap: () => controller.applyFilter(title),
      dense: true,
      hoverColor: AppTheme.folderYellow.withValues(alpha: 0.05),
      splashColor: AppTheme.folderYellow.withValues(alpha: 0.1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.folderYellow.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppTheme.folderYellow,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.noteResults.isEmpty && controller.folderResults.isEmpty) {
        return Center(
          child: Text(
            "No results found",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (controller.folderResults.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Text("Folders", style: theme.textTheme.titleLarge),
            ),
            GlassCard(
              borderRadius: 20,
              children: [
                for (int i = 0; i < controller.folderResults.length; i++) ...[
                  ListTile(
                    onTap: () => Get.toNamed(
                      Routes.NOTE_LIST,
                      arguments: controller.folderResults[i],
                    ),
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
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                  if (i < controller.folderResults.length - 1)
                    const Divider(indent: 56, height: 1),
                ],
              ],
            ),
            const SizedBox(height: 24),
          ],

          if (controller.noteResults.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Text("Notes", style: theme.textTheme.titleLarge),
            ),
            GlassCard(
              borderRadius: 20,
              children: [
                for (int i = 0; i < controller.noteResults.length; i++) ...[
                  ListTile(
                    onTap: () {
                      NoteNavigation.toDetail(controller.noteResults[i]);
                    },
                    title: Text(
                      controller.noteResults[i].title.isEmpty
                          ? "New Note"
                          : controller.noteResults[i].title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                  if (i < controller.noteResults.length - 1)
                    const Divider(indent: 16, height: 1),
                ],
              ],
            ),
          ],
          const SizedBox(height: 100), // Space for floating search bar
        ],
      );
    });
  }

  Widget _buildBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset > 0 ? 10 : 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.search,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller.searchController,
                      onChanged: controller.onSearchChanged,
                      autofocus: true,
                      cursorColor: AppTheme.folderYellow,
                      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 17),
                      decoration: InputDecoration(
                        hintText: "Search",
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          fontSize: 17,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.mic_fill,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              if (controller.isSearching.value) {
                controller.clearSearch();
              } else {
                Get.back();
              }
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                CupertinoIcons.xmark,
                color: theme.colorScheme.onSurface,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSearchBar(BuildContext context) {
    return _buildBottomBar(context);
  }
}
