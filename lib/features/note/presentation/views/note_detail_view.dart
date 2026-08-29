import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/features/note/presentation/widgets/note_content_editor.dart';
import 'package:Note/features/note/presentation/widgets/note_editor_toolbar.dart';
import 'package:Note/features/note/presentation/widgets/note_format_panel.dart';

class NoteDetailView extends GetView<NoteDetailController> {
  const NoteDetailView({super.key, this.tag});

  @override
  // ignore: overridden_fields
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemUiStyle(theme),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        resizeToAvoidBottomInset: false,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            NoteContentEditor(controller: controller),

            Obx(() {
              if (controller.isLoading.value || controller.isReadOnly.value) {
                return const SizedBox.shrink();
              }
              return Align(
                alignment: Alignment.bottomCenter,
                child: NoteEditorToolbar(
                  controller: controller,
                  onAttachmentAction: _handleAttachmentAction,
                ),
              );
            }),

            Obx(() {
              if (controller.isFormatPanelVisible.value) {
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: NoteFormatPanel(controller: controller),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  SystemUiOverlayStyle _systemUiStyle(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final style = isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return style.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: theme.scaffoldBackgroundColor,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
    );
  }

  void _handleAttachmentAction(String type) {
    switch (type) {
      case 'camera':
        controller.addAttachment(ImageSource.camera);
      case 'gallery':
        controller.addMediaAttachment();
      case 'drawing':
        controller.startDrawing();
      case 'scan_text':
        controller.scanText();
      case 'scan_text_photo':
        controller.scanTextFromGallery();
      case 'scan_docs':
        controller.scanDocuments();
      case 'scan_docs_photo':
        controller.scanDocumentsFromGallery();
      case 'audio':
        controller.recordAudio();
      case 'file':
        controller.addFileAttachment();
    }
  }
}
