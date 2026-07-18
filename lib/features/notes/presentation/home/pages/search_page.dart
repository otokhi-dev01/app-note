part of '../home_view.dart';

class _SearchPage extends StatelessWidget {
  const _SearchPage({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Obx(() {
        final hasFilter =
            controller.searchQuery.value.isNotEmpty ||
            controller.activeSearchToken.value != null;
        return ListView(
          key: const PageStorageKey('search_page'),
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: TextField(
                controller: controller.searchFieldController,
                autofocus: false,
                onChanged: controller.search,
                onSubmitted: controller.addRecentSearch,
                decoration: InputDecoration(
                  hintText: 'Search notes, tags, and attachments',
                  prefixIcon: const Icon(CupertinoIcons.search),
                  suffixIcon: controller.searchQuery.value.isEmpty
                      ? const Icon(CupertinoIcons.mic, size: 20)
                      : IconButton(
                          onPressed: () => controller.search(''),
                          icon: const Icon(CupertinoIcons.xmark_circle_fill),
                        ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            if (controller.activeSearchToken.value != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    label: Text(controller.activeSearchToken.value!),
                    onDeleted: controller.removeSearchToken,
                    deleteIcon: const Icon(CupertinoIcons.xmark, size: 14),
                  ),
                ),
              ),
            if (hasFilter) ...[
              _SectionHeading(
                title: 'Results',
                trailing: '${controller.filteredNotes.length} found',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: controller.filteredNotes.isEmpty
                    ? const _InlineEmpty(message: 'No matching notes found.')
                    : _NoteGroup(
                        notes: controller.filteredNotes,
                        controller: controller,
                      ),
              ),
            ] else ...[
              const _SectionHeading(title: 'Media Types'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _MediaTypeCard(
                      icon: CupertinoIcons.photo,
                      label: 'Photos',
                      onTap: () => controller.searchByFilter('attachments'),
                    ),
                    _MediaTypeCard(
                      icon: CupertinoIcons.doc_text_viewfinder,
                      label: 'Scans',
                      onTap: () => Get.toNamed(AppRoutes.media),
                    ),
                    _MediaTypeCard(
                      icon: CupertinoIcons.pencil_outline,
                      label: 'Drawings',
                      onTap: () => controller.searchByFilter('drawings'),
                    ),
                    _MediaTypeCard(
                      icon: CupertinoIcons.paperclip,
                      label: 'Files',
                      onTap: () => controller.searchByFilter('attachments'),
                    ),
                  ],
                ),
              ),
              if (controller.recentSearches.isNotEmpty) ...[
                const _SectionHeading(title: 'Recent Searches'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SurfaceCard(
                    child: Column(
                      children: controller.recentSearches
                          .take(4)
                          .toList()
                          .asMap()
                          .entries
                          .map(
                            (entry) => _RecentSearchRow(
                              value: entry.value,
                              isLast:
                                  entry.key ==
                                  controller.recentSearches.take(4).length - 1,
                              onTap: () => controller.search(entry.value),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
              const _SectionHeading(title: 'Discovery Tags'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _extractTags(controller.notes).map((tag) {
                    return ActionChip(
                      label: Text(tag),
                      onPressed: () => controller.search(tag),
                    );
                  }).toList(),
                ),
              ),
              const _SectionHeading(title: 'Smart Categories'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 104,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CategoryChip(
                        title: 'Receipts',
                        icon: CupertinoIcons.doc_text_search,
                        onTap: () => controller.searchCategory('Receipts'),
                      ),
                      _CategoryChip(
                        title: 'Travel',
                        icon: CupertinoIcons.airplane,
                        onTap: () => controller.searchCategory('Travel'),
                      ),
                      _CategoryChip(
                        title: 'Work',
                        icon: CupertinoIcons.briefcase,
                        onTap: () => controller.searchCategory('Work'),
                      ),
                      _CategoryChip(
                        title: 'Personal',
                        icon: CupertinoIcons.person,
                        onTap: () => controller.searchCategory('Personal'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}
