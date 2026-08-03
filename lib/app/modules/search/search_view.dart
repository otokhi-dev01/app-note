import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_widgets.dart';
import '../../routes/app_pages.dart';
import 'search_controller.dart' as sc;

class SearchView extends GetView<sc.SearchController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Sticky Top Bar for Search
            _buildTopBar(context),
            
            Expanded(
              child: Obx(() {
                if (controller.isSearching.value) {
                  return _buildSearchResults(context);
                }
                return _buildSuggestedSection(context);
              }),
            ),
            _buildBottomSearchBar(context),
          ],
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
            borderRadius: 22,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: Icon(Icons.chevron_left, color: theme.colorScheme.onSurfaceVariant, size: 30),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              "Suggested",
              style: theme.textTheme.titleLarge,
            ),
          ),
          LiquidGlassContainer(
            borderRadius: 15,
            opacity: 1.0, 
            child: Column(
              children: [
                for (int i = 0; i < controller.suggestions.length; i++) ...[
                  _buildSuggestionTile(
                    context,
                    controller.suggestions[i]['title'] as String,
                    controller.suggestions[i]['icon'] as IconData,
                  ),
                  if (i < controller.suggestions.length - 1)
                    const Divider(indent: 56, height: 1),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: () => controller.applyFilter(title),
      leading: Icon(icon, color: AppTheme.folderYellow, size: 24),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge,
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
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                    onTap: () => Get.toNamed(Routes.NOTE_LIST, arguments: controller.folderResults[i]),
                    leading: Icon(controller.folderResults[i].icon, color: AppTheme.folderYellow),
                    title: Text(controller.folderResults[i].name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    trailing: Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
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
                    onTap: () => Get.toNamed(Routes.NOTE_DETAIL, arguments: {"noteId": controller.noteResults[i].id}),
                    title: Text(controller.noteResults[i].title.isEmpty ? "New Note" : controller.noteResults[i].title, 
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    trailing: Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  ),
                  if (i < controller.noteResults.length - 1)
                    const Divider(indent: 16, height: 1),
                ],
              ],
            ),
          ],
        ],
      );
    });
  }

  Widget _buildBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: isDark ? null : [
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
                    Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller.searchController,
                        onChanged: controller.onSearchChanged,
                        autofocus: true,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: "Search",
                          hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 17),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Icon(Icons.mic, color: theme.colorScheme.onSurfaceVariant, size: 22),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: isDark ? null : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(Icons.close, color: theme.colorScheme.onSurface, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSearchBar(BuildContext context) {
    return _buildBottomBar(context);
  }
}
