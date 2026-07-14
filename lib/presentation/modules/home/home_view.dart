import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_controller.dart';
import 'home_style.dart';
import 'widgets/home_states.dart';
import 'widgets/home_widgets.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return Scaffold(
      backgroundColor: style.background,
      body: Stack(
        children: [
          Obx(() {
            return CustomScrollView(
              key: const ValueKey('home_scroll_view'),
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: _buildAllSlivers(context, style),
            );
          }),

          // Search Overlay
          Obx(() => controller.isSearching.value && 
                    controller.searchQuery.value.isEmpty && 
                    controller.activeSearchToken.value == null 
              ? SearchOverlay(style: style, controller: controller)
              : const SizedBox.shrink()),

          // Bottom Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Obx(() {
              if (controller.isSearching.value) {
                return SearchBottomBar(style: style, controller: controller);
              }
              return HomeBottomBar(
                style: style,
                noteCount: controller.isFolderView.value 
                    ? controller.notes.length 
                    : controller.filteredNotes.length + controller.pinnedNotes.length,
                isFolderView: controller.isFolderView.value,
                onSearch: controller.startSearch,
                onCreateNote: controller.openCreateNote,
                onCreateFolder: controller.openCreateFolder,
              );
            }),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAllSlivers(BuildContext context, HomeStyle style) {
    final isSearching = controller.isSearching.value;
    final isFolderView = controller.isFolderView.value;
    final isTrashView = controller.isTrashView.value;
    final query = controller.searchQuery.value;
    final token = controller.activeSearchToken.value;

    final List<Widget> slivers = [];

    // 1. Header
    if (!isSearching) {
      slivers.add(SliverPersistentHeader(
        pinned: true,
        delegate: HomeHeaderDelegate(
          style: style,
          controller: controller,
          topPadding: MediaQuery.of(context).padding.top,
        ),
      ));
    }

    // 2. Content
    if (!isSearching) {
      if (controller.isLoading.value) {
        slivers.add(LoadingNotes(style: style));
      } else if (isTrashView) {
        slivers.add(TrashList(style: style, controller: controller));
      } else if (isFolderView) {
        slivers.add(FoldersList(style: style, controller: controller));
      } else {
        slivers.addAll(_buildNotesList(context, style));
      }
    } else {
      if (query.isNotEmpty || token != null) {
        slivers.addAll(_buildSearchResults(style));
      } else {
        slivers.add(const SliverToBoxAdapter(child: SizedBox.shrink()));
      }
    }

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 100)));
    return slivers;
  }

  List<Widget> _buildNotesList(BuildContext context, HomeStyle style) {
    final pinned = controller.pinnedNotes;
    final others = controller.filteredNotes;

    if (pinned.isEmpty && others.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.doc_plaintext, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              const Text(
                'No Notes', 
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.black)
              ),
            ],
          ),
        ),
      ];
    }

    return [
      if (pinned.isNotEmpty) ...[
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(22, 16, 22, 8),
            child: Text('PINNED', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
        ),
        NotesGrid(key:  ValueKey('pinned_grid'), notes: pinned, style: style, controller: controller),
      ],
      if (others.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(22, 24, 22, 8),
            child: Text(pinned.isNotEmpty ? 'NOTES' : 'ALL NOTES', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
        ),
        NotesGrid(key: ValueKey('others_grid'), notes: others, style: style, controller: controller),
      ],
    ];
  }

  List<Widget> _buildSearchResults(HomeStyle style) {
    final results = controller.filteredNotes;
    final topHits = results.take(2).toList();
    final others = results.skip(2).toList();

    return [
      if (topHits.isNotEmpty) ...[
        _buildSearchSectionHeader('Top Hits', topHits.length),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: FolderSection(
              style: style,
              children: topHits.asMap().entries.map((entry) {
                final note = entry.value;
                final isLast = entry.key == topHits.length - 1;
                return SearchNoteCard(note: note, controller: controller, isLast: isLast);
              }).toList(),
            ),
          ),
        ),
      ],
      if (others.isNotEmpty) ...[
        _buildSearchSectionHeader('Notes', others.length),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: FolderSection(
              style: style,
              children: others.asMap().entries.map((entry) {
                final note = entry.value;
                final isLast = entry.key == others.length - 1;
                return SearchNoteCard(note: note, controller: controller, isLast: isLast);
              }).toList(),
            ),
          ),
        ),
      ],
    ];
  }

  Widget _buildSearchSectionHeader(String title, int count) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('$count Found', style: const TextStyle(fontSize: 15, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
