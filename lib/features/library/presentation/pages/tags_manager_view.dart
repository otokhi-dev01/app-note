import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/features/library/application/library_coordinator.dart';
import 'package:notes/features/library/application/library_note_queries.dart';

import '../widgets/library_components.dart';

class TagsManagerView extends GetView<LibraryCoordinator> {
  const TagsManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return LibraryScaffold(
      title: 'Tags',
      action: TextButton(
        onPressed: controller.openCreateNote,
        child: const Text('New Note'),
      ),
      child: Obx(() {
        final tags = libraryTagCounts(controller.notes);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
          children: [
            const LibraryFeatureIntro(
              title: 'Tags Manager',
              subtitle: 'Browse tags extracted from your saved notes',
              icon: CupertinoIcons.tag,
              compact: true,
            ),
            const SizedBox(height: 22),
            if (tags.isEmpty)
              const LibraryFeatureEmpty(
                message: 'Type #work or another tag in a note to add it here.',
                icon: CupertinoIcons.tag,
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
                          minTileHeight: 68,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          leading: const LibraryFeatureIcon(
                            CupertinoIcons.tag,
                            size: 40,
                            iconSize: 19,
                          ),
                          title: Text(
                            tag.key,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${tag.value}',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                CupertinoIcons.chevron_right,
                                color: colors.onSurfaceVariant.withValues(
                                  alpha: .72,
                                ),
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                        if (entry.key != tags.length - 1)
                          Divider(
                            height: 1,
                            indent: 72,
                            color: colors.outlineVariant.withValues(alpha: .55),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 22),
            Text(
              '${tags.length} tags · ${controller.notes.length} notes total',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        );
      }),
    );
  }
}
