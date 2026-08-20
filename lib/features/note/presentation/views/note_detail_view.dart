import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/features/note/presentation/widgets/note_content_editor.dart';
import 'package:Note/features/note/presentation/widgets/note_detail_more_popup.dart';
import 'package:Note/features/note/presentation/widgets/note_editor_toolbar.dart';
import 'package:Note/features/note/presentation/widgets/note_format_panel.dart';

import 'package:Note/features/note/presentation/widgets/note_attachment_popup.dart';
import 'package:Note/core/feedback/app_snackbar.dart';

class NoteDetailView extends GetView<NoteDetailController> {
  // Must match the tag NoteBinding registered the controller under for this
  // push (see NoteNavigation._newInstanceTag and app_pages.dart) so this page
  // finds the instance built for it specifically, not whichever NOTE_DETAIL
  // page opened first.
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
            NoteContentEditor(
              controller: controller,
              onShowMoreMenu: () => _showMoreMenu(context),
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
            // Format Panel
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

  void _showMoreMenu(BuildContext context) {
    NoteDetailMorePopup.show(context: context, controller: controller);
  }

  void _showAttachmentPopup(BuildContext context) {
    NoteAttachmentPopup.show(
      context: context,
      onAction: (type) {
        switch (type) {
          case 'camera':
            controller.addAttachment(ImageSource.camera);
          case 'gallery':
            controller.addAttachment(ImageSource.gallery);
          case 'drawing':
            controller.startDrawing();
          // These need a native scanner / audio recorder / file picker this
          // app doesn't have yet — say so instead of the button doing
          // nothing when tapped.
          case 'scan_text':
          case 'scan_docs':
            AppSnackbar.info('Coming soon', 'Scanning isn\'t available yet.');
          case 'audio':
            AppSnackbar.info(
              'Coming soon',
              'Audio recording isn\'t available yet.',
            );
          case 'file':
            controller.addFileAttachment();
        }
      },
    );
  }
}
