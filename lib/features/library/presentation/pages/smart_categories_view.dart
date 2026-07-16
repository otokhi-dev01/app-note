import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/features/library/application/library_coordinator.dart';

import '../widgets/library_components.dart';

class SmartCategoriesView extends GetView<LibraryCoordinator> {
  const SmartCategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const categories = [
      LibraryCategoryDefinition('Receipts', CupertinoIcons.doc_text_search, [
        'receipt',
        'invoice',
        'total',
        'purchase',
      ]),
      LibraryCategoryDefinition('Travel', CupertinoIcons.airplane, [
        'travel',
        'trip',
        'flight',
        'hotel',
      ]),
      LibraryCategoryDefinition('Work', CupertinoIcons.briefcase, [
        'work',
        'project',
        'meeting',
        'client',
      ]),
      LibraryCategoryDefinition('Personal', CupertinoIcons.person, [
        'personal',
        'home',
        'family',
        'journal',
      ]),
    ];
    return LibraryScaffold(
      title: 'Smart Categories',
      child: Obx(() {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
          children: [
            const LibraryFeatureIntro(
              title: 'Smart Categories',
              subtitle: 'Automatically grouped from your note text',
              icon: CupertinoIcons.sparkles,
              compact: true,
            ),
            const SizedBox(height: 22),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .95,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                final count = controller.notes.where((note) {
                  final value = '${note.title} ${note.content}'.toLowerCase();
                  return category.patterns.any(value.contains);
                }).length;
                return LibrarySurface(
                  child: InkWell(
                    onTap: () {
                      Get.back<void>();
                      controller.searchCategory(category.title);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(17),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LibraryFeatureIcon(
                                category.icon,
                                size: 46,
                                iconSize: 21,
                              ),
                              const Spacer(),
                              Icon(
                                CupertinoIcons.chevron_right,
                                color: colors.onSurfaceVariant.withValues(
                                  alpha: .62,
                                ),
                                size: 14,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            category.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            count == 1 ? '1 note' : '$count notes',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      }),
    );
  }
}
