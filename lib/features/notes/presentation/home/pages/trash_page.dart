part of '../home_view.dart';

class _DeletedPage extends StatelessWidget {
  const _DeletedPage({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppBrandBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Obx(() {
            return Column(
              children: [
                _CompactBar(
                  title: 'Recently Deleted',
                  onBack: controller.showFolders,
                  actionLabel: 'Edit',
                  onAction: () {},
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
                    children: [
                      Text(
                        'Notes are available here for 30 days. After that time, notes can be permanently deleted.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 17,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (controller.trashNotes.isEmpty)
                        const _InlineEmpty(
                          message: 'Recently Deleted is empty.',
                        )
                      else
                        _SurfaceCard(
                          child: Column(
                            children: controller.trashNotes
                                .asMap()
                                .entries
                                .map(
                                  (entry) => _DeletedRow(
                                    note: entry.value,
                                    isLast:
                                        entry.key ==
                                        controller.trashNotes.length - 1,
                                    onTap: () => _showDeletedActions(
                                      context,
                                      controller,
                                      entry.value,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                AppGlassSurface(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    MediaQuery.paddingOf(context).bottom + 10,
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: controller.trashNotes.isEmpty
                            ? null
                            : controller.clearTrash,
                        child: Text(
                          'Delete All',
                          style: TextStyle(color: scheme.error),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: controller.trashNotes.isEmpty
                            ? null
                            : controller.restoreAllNotes,
                        child: const Text('Recover All'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
