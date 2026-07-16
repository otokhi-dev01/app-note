part of '../home_view.dart';

class _NotesPage extends StatelessWidget {
  const _NotesPage({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Obx(() {
        final pinned = controller.pinnedNotes;
        final notes = controller.filteredNotes;
        return RefreshIndicator(
          onRefresh: controller.loadNotes,
          color: scheme.primary,
          child: CustomScrollView(
            key: const PageStorageKey('notes_page'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _LinenHeader(
                  title: controller.selectedFolder.value?.name ?? 'Notes',
                  onMenu: () => _showAppMenu(context, controller),
                  actions: [
                    IconButton(
                      onPressed: controller.toggleViewMode,
                      tooltip: controller.isGalleryView.value
                          ? 'List view'
                          : 'Gallery view',
                      icon: Icon(
                        controller.isGalleryView.value
                            ? CupertinoIcons.list_bullet
                            : CupertinoIcons.square_grid_2x2,
                        color: scheme.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: controller.goToSettings,
                      icon: Icon(
                        CupertinoIcons.ellipsis_vertical,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: _SearchField(
                    hint: 'Search notes',
                    readOnly: true,
                    onTap: () => controller.selectTab(2),
                  ),
                ),
              ),
              if (controller.isLoading.value)
                const SliverFillRemaining(
                  child: Center(child: CupertinoActivityIndicator()),
                )
              else if (controller.errorMessage.value != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(
                    message: controller.errorMessage.value!,
                    onRetry: controller.loadNotes,
                  ),
                )
              else if (pinned.isEmpty && notes.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: CupertinoIcons.doc_text,
                    title: 'Start your first note',
                    message: 'Capture an idea, checklist, scan, or drawing.',
                    actionLabel: 'New Note',
                    onAction: controller.openCreateNote,
                  ),
                )
              else ...[
                if (pinned.isNotEmpty) ...[
                  const _SliverSectionTitle(title: 'PINNED'),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: _PinnedCard(
                        note: pinned.first,
                        onTap: () => controller.openNote(pinned.first),
                        onShare: () => controller.shareNote(pinned.first),
                      ),
                    ),
                  ),
                ],
                _SliverSectionTitle(
                  title:
                      controller.selectedFolder.value?.name.toUpperCase() ??
                      'ALL NOTES',
                  trailing: '${pinned.length + notes.length} notes',
                ),
                if (controller.isGalleryView.value)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: .88,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _NoteGalleryCard(
                          note: notes[index],
                          onTap: () => controller.openNote(notes[index]),
                        ),
                        childCount: notes.length,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: _NoteGroup(notes: notes, controller: controller),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ],
          ),
        );
      }),
    );
  }
}
