import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/app/theme/app_colors.dart';
import 'package:notes/features/library/application/library_coordinator.dart';

import '../library_helpers.dart';
import '../widgets/library_components.dart';

class SmartCategoriesView extends GetView<LibraryCoordinator> {
  const SmartCategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
          children: [
            const LibraryFeatureIntro(
              title: 'Smart Categories',
              subtitle: 'Automatically grouped from your note text',
              icon: CupertinoIcons.sparkles,
              compact: true,
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                final count = controller.notes.where((note) {
                  final value = '${note.title} ${note.content}'.toLowerCase();
                  return category.patterns.any(value.contains);
                }).length;
                return Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () {
                      Get.back<void>();
                      controller.searchCategory(category.title);
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: libraryCardDecoration(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LibraryFeatureIcon(category.icon),
                          const Spacer(),
                          Text(
                            category.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '$count notes',
                            style: const TextStyle(color: AppColors.subtitle),
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
