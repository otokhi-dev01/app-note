import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';
import 'package:Note/features/note/presentation/widgets/note_block_list.dart';
import 'package:Note/features/note/presentation/widgets/note_editor_header.dart';
import 'package:Note/features/note/presentation/widgets/note_editor_toolbar.dart';
import 'package:Note/features/note/presentation/widgets/note_editor_top_bar.dart';
import 'package:Note/features/note/presentation/widgets/note_format_panel.dart';

class CreateNoteView extends GetView<NoteDetailController> {
  const CreateNoteView({super.key, this.tag});

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
        body: Stack(
          children: [
            _CreateNoteBody(controller: controller),

            Obx(() {
              if (controller.isReadOnly.value) {
                return const SizedBox.shrink();
              }
              return Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),

                  child: controller.isFormatPanelVisible.value
                      ? Padding(
                          key: const ValueKey('format-panel'),
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.viewInsetsOf(context).bottom,
                          ),
                          child: NoteFormatPanel(controller: controller),
                        )
                      : NoteEditorToolbar(
                          key: const ValueKey('bottom-toolbar'),
                          controller: controller,
                          isCreating: true,
                          onAttachmentAction: (type) =>
                              _handleAttachmentAction(type),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
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
}

Future<void> _handleBack(NoteDetailController controller) async {
  await controller.saveAndExitIfNeeded();
  Get.back(result: true);
}

class _CreateNoteBody extends StatelessWidget {
  final NoteDetailController controller;

  const _CreateNoteBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final horizontalInset = (MediaQuery.sizeOf(context).width * 0.065).clamp(
      21.0,
      32.0,
    );

    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom + 140;

    return _MaxWidth(
      child: Obx(() {
        final isReadOnly = controller.isReadOnly.value;
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          slivers: [
            NoteEditorTopBar(
              controller: controller,
              title: 'note_list_new_note'.tr,
              showShare: false,
              showMore: false,
              alwaysShowSave: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              onBack: () => _handleBack(controller),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalInset,
                16,
                horizontalInset,
                bottomPadding,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  NoteEditorHeader(controller: controller),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('create-note-title-field'),
                    controller: controller.titleController,
                    focusNode: controller.titleFocusNode,
                    enabled: !isReadOnly,

                    autofocus: !isReadOnly,
                    onTap: () => controller.activeBlockIndex.value = -1,
                    cursorColor: AppTheme.folderYellow,
                    cursorWidth: 1.5,
                    maxLines: null,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => controller.focusFirstTextBlock(),
                    textCapitalization: TextCapitalization.sentences,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'note_editor_title_hint'.tr,
                      hintStyle: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: 32,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isCollapsed: true,
                      filled: false,
                      fillColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  NoteBlockList(
                    controller: controller,
                    textPlaceholder: 'note_editor_start_writing_placeholder'.tr,
                  ),
                ]),
              ),
            ),

            if (!isReadOnly)
              SliverFillRemaining(
                hasScrollBody: false,
                fillOverscroll: false,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: controller.focusLastTextBlock,
                  child: const SizedBox(width: double.infinity),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _MaxWidth extends StatelessWidget {
  final Widget child;
  const _MaxWidth({required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
