import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:notes/app/theme/app_colors.dart';
import 'package:notes/core/presentation/images/image_helper.dart';
import 'package:notes/features/notes/domain/entities/note.dart';
import 'package:notes/features/library/application/library_coordinator.dart';

import '../library_helpers.dart';
import '../widgets/library_components.dart';

class MediaGalleryView extends GetView<LibraryCoordinator> {
  const MediaGalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    return LibraryScaffold(
      title: 'Attachments',
      child: Obx(() {
        final media = <({String path, Note note})>[
          for (final note in controller.notes)
            for (final path in note.imagePaths) (path: path, note: note),
        ];
        return RefreshIndicator(
          onRefresh: controller.loadNotes,
          color: AppColors.primary,
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
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: .78,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = media[index];
                      return Material(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          onTap: () => controller.openNote(item.note),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            decoration: libraryCardDecoration(context),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ImageHelper.buildSafeImage(
                                    item.path,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.note.title.isEmpty
                                            ? 'Untitled'
                                            : item.note.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat.MMMd().format(
                                          item.note.updatedAt,
                                        ),
                                        style: const TextStyle(
                                          color: AppColors.subtitle,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
