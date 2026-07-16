import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:notes/core/presentation/images/image_helper.dart';
import 'package:notes/features/notes/domain/entities/note.dart';
import 'package:notes/features/library/application/library_coordinator.dart';

import '../widgets/library_components.dart';

class MediaGalleryView extends GetView<LibraryCoordinator> {
  const MediaGalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LibraryScaffold(
      title: 'Attachments',
      child: Obx(() {
        final media = <({String path, Note note})>[
          for (final note in controller.notes)
            for (final path in note.imagePaths) (path: path, note: note),
        ];
        return RefreshIndicator(
          onRefresh: controller.loadNotes,
          color: colors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: LibraryFeatureIntro(
                  title: 'Media Gallery',
                  subtitle: '${media.length} attachments across your notes',
                  icon: CupertinoIcons.photo_on_rectangle,
                ),
              ),
              if (media.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: LibraryFeatureEmpty(
                    message: 'Photos, scans, and drawings will appear here.',
                    icon: CupertinoIcons.photo_on_rectangle,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 240,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: .8,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = media[index];
                      return LibrarySurface(
                        child: InkWell(
                          onTap: () => controller.openNote(item.note),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ColoredBox(
                                  color: colors.surfaceContainerHighest,
                                  child: ImageHelper.buildSafeImage(
                                    item.path,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  14,
                                  13,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.note.title.isEmpty
                                          ? 'Untitled'
                                          : item.note.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      DateFormat.MMMd().format(
                                        item.note.updatedAt,
                                      ),
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: media.length),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
