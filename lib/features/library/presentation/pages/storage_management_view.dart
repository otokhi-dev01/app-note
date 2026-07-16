import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/app/navigation/app_routes.dart';
import 'package:notes/app/theme/app_colors.dart';
import 'package:notes/features/library/application/library_coordinator.dart';
import 'package:notes/features/library/application/attachment_size_query.dart';

import '../library_helpers.dart';
import '../widgets/library_components.dart';

class StorageManagementView extends GetView<LibraryCoordinator> {
  const StorageManagementView({super.key});

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: libraryCardDecoration(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('STORAGE USAGE', style: libraryFeatureEyebrow),
                      const SizedBox(height: 10),
                      Text(
                        '${megabytes.toStringAsFixed(1)} MB',
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Local note attachments',
                        style: TextStyle(color: AppColors.subtitle),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (megabytes / 1024).clamp(0, 1),
                          minHeight: 12,
                          color: AppColors.primary,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
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
                const SizedBox(height: 28),
                const Text('RECOMMENDATION', style: libraryFeatureEyebrow),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: libraryCardDecoration(context),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LibraryFeatureIcon(CupertinoIcons.cloud_download),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Keep important files backed up',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Notes currently stay on this device and are scoped to your authenticated account.',
                              style: TextStyle(
                                color: AppColors.subtitle,
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
