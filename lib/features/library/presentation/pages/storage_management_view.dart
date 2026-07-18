import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/app/navigation/app_routes.dart';
import 'package:notes/features/library/application/library_coordinator.dart';
import 'package:notes/features/library/application/attachment_size_query.dart';

import '../library_helpers.dart';
import '../widgets/library_components.dart';

class StorageManagementView extends GetView<LibraryCoordinator> {
  const StorageManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return LibraryScaffold(
      title: 'Storage',
      child: Obx(() {
        final notes = controller.notes.toList(growable: false);
        final attachmentCount = notes.fold<int>(
          0,
          (sum, note) => sum + note.imagePaths.length,
        );
        return FutureBuilder<int>(
          future: Get.find<AttachmentSizeQuery>().calculate(notes),
          builder: (context, snapshot) {
            final bytes = snapshot.data ?? 0;
            final megabytes = bytes / 1048576;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: libraryCardDecoration(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Storage Usage',
                              style: libraryFeatureEyebrow(context),
                            ),
                          ),
                          const LibraryFeatureIcon(
                            CupertinoIcons.archivebox,
                            size: 44,
                            iconSize: 21,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${megabytes.toStringAsFixed(1)} MB',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                      ),
                      Text(
                        'Local note attachments',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 22),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: (megabytes / 1024).clamp(0, 1),
                          minHeight: 10,
                          color: colors.primary,
                          backgroundColor: colors.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const LibrarySectionHeader(title: 'By category'),
                LibrarySurface(
                  child: Column(
                    children: [
                      LibraryStorageRow(
                        icon: CupertinoIcons.doc_text,
                        title: 'Notes',
                        value: '${notes.length} items',
                        onTap: () {
                          Get.back<void>();
                          controller.selectTab(0);
                        },
                      ),
                      LibraryStorageRow(
                        icon: CupertinoIcons.photo,
                        title: 'Attachments',
                        value: '$attachmentCount files',
                        onTap: () => Get.toNamed(AppRoutes.media),
                      ),
                      LibraryStorageRow(
                        icon: CupertinoIcons.trash,
                        title: 'Recently Deleted',
                        value: '${controller.trashNotes.length} items',
                        onTap: () {
                          Get.back<void>();
                          controller.showTrash();
                        },
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const LibrarySectionHeader(title: 'Recommendation'),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: .14),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LibraryFeatureIcon(
                        CupertinoIcons.cloud_download,
                        size: 44,
                        iconSize: 21,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Keep important files backed up',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Notes currently stay on this device and are scoped to your authenticated account.',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}
