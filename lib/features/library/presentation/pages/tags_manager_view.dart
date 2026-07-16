import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/app/theme/app_colors.dart';
import 'package:notes/features/library/application/library_coordinator.dart';
import 'package:notes/features/library/application/library_note_queries.dart';

import '../widgets/library_components.dart';

class TagsManagerView extends GetView<LibraryCoordinator> {
  const TagsManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    return LibraryScaffold(
      title: 'Tags',
      action: TextButton(
        onPressed: controller.openCreateNote,
        child: const Text('New Note'),
      ),
      child: Obx(() {
        final tags = libraryTagCounts(controller.notes);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
          children: [
            const LibraryFeatureIntro(
              title: 'Tags Manager',
              subtitle: 'Browse tags extracted from your saved notes',
              icon: CupertinoIcons.tag,
              compact: true,
            ),
            const SizedBox(height: 18),
            if (tags.isEmpty)
              const LibraryFeatureEmpty(
                message: 'Type #work or another tag in a note to add it here.',
              )
            else
              LibrarySurface(
                child: Column(
                  children: tags.entries.toList().asMap().entries.map((entry) {
                    final tag = entry.value;
                    return Column(
                      children: [
                        ListTile(
                          onTap: () {
                            Get.back<void>();
                            controller.selectTab(2);
                            controller.search(tag.key);
                          },
                          leading: const Icon(
                            CupertinoIcons.tag,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            tag.key,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${tag.value}',
                                style: const TextStyle(
                                  color: AppColors.subtitle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                CupertinoIcons.chevron_right,
                                size: 15,
                              ),
                            ],
                          ),
                        ),
                        if (entry.key != tags.length - 1)
                          const Divider(height: 1, indent: 56),
                      ],
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 22),
            Text(
              '${tags.length} tags · ${controller.notes.length} notes total',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.subtitle),
            ),
          ],
        );
      }),
    );
  }
}
