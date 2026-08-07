import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/note_detail_controller.dart';
import '../widgets/note_content_editor.dart';
import '../widgets/note_detail_more_popup.dart';
import '../widgets/note_editor_toolbar.dart';
import '../widgets/note_editor_top_bar.dart';

class NoteDetailView extends GetView<NoteDetailController> {
  const NoteDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemUiStyle(theme),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        resizeToAvoidBottomInset: true,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Obx(
              () => controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : NoteContentEditor(controller: controller),
            ),
            Column(
              children: [
                NoteEditorTopBar(
                  controller: controller,
                  onShowMoreMenu: () => _showMoreMenu(context),
                ),
                Obx(
                  () => controller.isReadOnly.value
                      ? _buildReadOnlyBanner(context)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            // Floating Toolbar that follows keyboard
            Obx(() {
              if (controller.isLoading.value || controller.isReadOnly.value) {
                return const SizedBox.shrink();
              }
              return Align(
                alignment: Alignment.bottomCenter,
                child: NoteEditorToolbar(
                  controller: controller,
                  onShowAttachmentPopup: () => _showAttachmentPopup(context),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  SystemUiOverlayStyle _systemUiStyle(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final style = isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    return style.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: theme.scaffoldBackgroundColor,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );
  }

  void _showMoreMenu(BuildContext context) {
    Get.dialog(
      NoteDetailMorePopup(controller: controller),
      barrierColor: Colors.black.withValues(alpha: 0.1),
    );
  }

  void _showAttachmentPopup(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Attachment'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => _pickAttachment(ImageSource.camera),
            child: const Text('Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => _pickAttachment(ImageSource.gallery),
            child: const Text('Photo Library'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => _pickAttachment(ImageSource.camera, isVideo: true),
            child: const Text('Take Video'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: Get.back,
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _pickAttachment(ImageSource source, {bool isVideo = false}) {
    Get.back();
    controller.addAttachment(source, isVideo: isVideo);
  }

  Widget _buildReadOnlyBanner(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: Colors.orange.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This note is in Recently Deleted. Restore it to make changes.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Tip', 'Use Recently Deleted to restore this note.');
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'OK',
              style: TextStyle(
                color: Colors.orange[900],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
