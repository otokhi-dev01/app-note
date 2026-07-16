import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes/core/constants/app_strings.dart';
import 'package:notes/core/formatters/date_formatter.dart';
import '../home/home_style.dart';
import 'package:notes/core/presentation/images/image_helper.dart';
import 'detail_controller.dart';

class DetailView extends GetView<DetailController> {
  const DetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return Scaffold(
      backgroundColor: style.background,
      appBar: AppBar(
        backgroundColor: style.background,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          AppStrings.noteDetails,
          style: TextStyle(
            color: style.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Obx(
            () => IconButton(
              tooltip: controller.note.value?.isPinned == true
                  ? 'Unpin note'
                  : 'Pin note',
              onPressed: controller.togglePin,
              icon: Icon(
                controller.note.value?.isPinned == true
                    ? CupertinoIcons.pin_fill
                    : CupertinoIcons.pin,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: style.surface,
          border: Border(top: BorderSide(color: style.border, width: .5)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  tooltip: 'Add attachment',
                  onPressed: () => _showAttachmentOptions(context),
                  icon: const Icon(CupertinoIcons.camera),
                ),
                IconButton(
                  tooltip: 'Move note',
                  onPressed: controller.moveNote,
                  icon: const Icon(CupertinoIcons.folder),
                ),
                IconButton(
                  tooltip: 'Edit note',
                  onPressed: controller.edit,
                  icon: const Icon(CupertinoIcons.square_pencil),
                ),
                IconButton(
                  tooltip: 'Delete note',
                  onPressed: controller.delete,
                  icon: Icon(
                    CupertinoIcons.trash,
                    color: style.theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CupertinoActivityIndicator());
        }
        final error = controller.errorMessage.value;
        if (error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    color: style.secondaryText,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: style.secondaryText),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: controller.loadNote,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }
        final note = controller.note.value;
        if (note == null) {
          return Center(
            child: Text(
              'Note not found.',
              style: TextStyle(color: style.secondaryText),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
              decoration: BoxDecoration(
                color: style.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: style.shadow,
                    blurRadius: 20,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title.isEmpty ? 'Untitled' : note.title,
                    style: style.theme.textTheme.headlineMedium?.copyWith(
                      color: style.primaryText,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.clock,
                        size: 14,
                        color: style.secondaryText,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Updated ${DateFormatter.format(note.updatedAt)}',
                        style: TextStyle(
                          color: style.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 34),
                  Text(
                    note.content.isEmpty ? 'No content yet.' : note.content,
                    style: style.theme.textTheme.bodyLarge?.copyWith(
                      color: style.primaryText,
                      height: 1.5,
                    ),
                  ),
                  if (note.imagePaths.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.paperclip,
                          size: 18,
                          color: style.theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Attachments',
                          style: style.theme.textTheme.titleMedium?.copyWith(
                            color: style.theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 240,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: note.imagePaths.length,
                        itemBuilder: (context, index) {
                          final path = note.imagePaths[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      controller.editImage(path, index),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: style.border),
                                      boxShadow: [
                                        BoxShadow(
                                          color: style.shadow,
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ImageHelper.buildSafeImage(
                                      path,
                                      width: 200,
                                      height: 220,
                                      radius: 20,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: GestureDetector(
                                    onTap: () => controller.removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: style.surface.withValues(
                                          alpha: 0.8,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: style.border),
                                      ),
                                      child: Icon(
                                        CupertinoIcons.xmark,
                                        color: style.theme.colorScheme.error,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CupertinoIcons.pencil,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Tap to edit',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Add Attachment'),
        message: const Text(
          'Take a photo or choose from your library to add it to your note.',
        ),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Camera'),
            onPressed: () {
              Get.back();
              controller.addImage(ImageSource.camera);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Photo Library'),
            onPressed: () {
              Get.back();
              controller.addImage(ImageSource.gallery);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Get.back(),
        ),
      ),
    );
  }
}
