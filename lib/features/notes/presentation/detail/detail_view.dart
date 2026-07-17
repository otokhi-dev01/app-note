import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes/core/constants/app_strings.dart';
import 'package:notes/core/formatters/date_formatter.dart';
import 'package:notes/core/presentation/brand/app_brand.dart';
import 'package:notes/features/notes/domain/entities/note.dart';
import '../home/home_style.dart';
import 'package:notes/core/presentation/images/image_helper.dart';
import 'detail_controller.dart';

class DetailView extends GetView<DetailController> {
  const DetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return AppBrandBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
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
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: AppGlassSurface(
            borderRadius: BorderRadius.circular(28),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
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
                    _NoteStatementBlocks(
                      note: note,
                      style: style,
                      controller: controller,
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
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

class _NoteStatementBlocks extends StatelessWidget {
  const _NoteStatementBlocks({
    required this.note,
    required this.style,
    required this.controller,
  });

  final Note note;
  final HomeStyle style;
  final DetailController controller;

  @override
  Widget build(BuildContext context) {
    final statements = note.content.split('\n');
    final lastStatement = statements.length - 1;
    final anchors = List<int>.generate(note.imagePaths.length, (index) {
      return index < note.imageAnchors.length
          ? note.imageAnchors[index].clamp(0, lastStatement)
          : lastStatement;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(statements.length, (statementIndex) {
        final images = List<int>.generate(
          note.imagePaths.length,
          (i) => i,
        ).where((imageIndex) => anchors[imageIndex] == statementIndex);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (statements[statementIndex].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  statements[statementIndex],
                  style: style.theme.textTheme.bodyLarge?.copyWith(
                    color: style.primaryText,
                    height: 1.5,
                  ),
                ),
              )
            else if (note.content.isEmpty && note.imagePaths.isEmpty)
              Text(
                'No content yet.',
                style: TextStyle(color: style.secondaryText),
              ),
            ...images.map(
              (imageIndex) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () => controller.editImage(
                        note.imagePaths[imageIndex],
                        imageIndex,
                      ),
                      child: ImageHelper.buildSafeImage(
                        note.imagePaths[imageIndex],
                        width: double.infinity,
                        height: 250,
                        radius: 18,
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: IconButton.filledTonal(
                        tooltip: 'Remove image',
                        onPressed: () => controller.removeImage(imageIndex),
                        icon: const Icon(CupertinoIcons.xmark, size: 16),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Chip(
                        avatar: const Icon(CupertinoIcons.pencil, size: 14),
                        label: const Text('Tap to edit'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: style.surface.withValues(alpha: .88),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
