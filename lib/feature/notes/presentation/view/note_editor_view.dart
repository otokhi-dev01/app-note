import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../controllers/note_editor_controller.dart';

class NoteEditorView
    extends GetView<NoteEditorController> {
  const NoteEditorView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: Get.back,
          child: Icon(
            CupertinoIcons.back,
            color: theme.colorScheme.onSurface,
          ),
        ),
        title: const Text('Edit Note'),
        actions: <Widget>[
          Obx(
                () => CupertinoButton(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              onPressed: controller.isSaving.value
                  ? null
                  : controller.saveChanges,
              child: controller.isSaving.value
                  ? const CupertinoActivityIndicator()
                  : Text(
                'Save',
                style: TextStyle(
                  color:
                  theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusManager.instance.primaryFocus
              ?.unfocus();
        },
        child: Obx(
              () => _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context,
      ) {
    if (controller.isLoading.value) {
      return const Center(
        child: CupertinoActivityIndicator(
          radius: 14,
        ),
      );
    }

    final String error =
    controller.errorMessage.value.trim();

    if (error.isNotEmpty &&
        controller.note.value == null) {
      return _NoteEditorErrorState(
        message: error,
        onRetry: controller.reloadNote,
      );
    }

    return _NoteEditorContent(
      controller: controller,
      onAddAttachment: () {
        _showAttachmentOptions(context);
      },
    );
  }

  Future<void> _showAttachmentOptions(
      BuildContext context,
      ) async {
    FocusManager.instance.primaryFocus
        ?.unfocus();

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (
          BuildContext sheetContext,
          ) {
        return CupertinoActionSheet(
          title: const Text('Add Image'),
          message: const Text(
            'Take a new photo or select one from your photo library.',
          ),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();

                _pickAndUploadImage(
                  source: ImageSource.camera,
                );
              },
              child: const Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    CupertinoIcons.camera,
                    size: 21,
                  ),
                  SizedBox(width: 9),
                  Text('Take Photo'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();

                _pickAndUploadImage(
                  source: ImageSource.gallery,
                );
              },
              child: const Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    CupertinoIcons.photo,
                    size: 21,
                  ),
                  SizedBox(width: 9),
                  Text('Choose Photo'),
                ],
              ),
            ),
          ],
          cancelButton:
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetContext).pop();
            },
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage({
    required ImageSource source,
  }) async {
    if (controller.isSaving.value) {
      return;
    }

    try {
      controller.isSaving.value = true;
      controller.errorMessage.value = '';

      final ImagePicker imagePicker =
      ImagePicker();

      final XFile? selectedImage =
      await imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
        preferredCameraDevice:
        CameraDevice.rear,
      );

      if (selectedImage == null) {
        return;
      }

      final int currentContentCount =
          controller.note.value?.content.length ??
              0;

      await controller.noteRepository
          .uploadAttachment(
        noteId: controller.noteId,
        filePath: selectedImage.path,
        blockId: const Uuid().v4(),
        displayOrder:
        currentContentCount + 1,
      );

      await controller.reloadNote();

      Get.snackbar(
        'Image uploaded',
        'The image was added to your note.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      controller.errorMessage.value =
          _cleanError(error);
    } finally {
      controller.isSaving.value = false;
    }
  }

  String _cleanError(
      Object error,
      ) {
    return error
        .toString()
        .replaceFirst(
      'ApiException: ',
      '',
    )
        .replaceFirst(
      'Exception: ',
      '',
    )
        .trim();
  }
}

class _NoteEditorContent
    extends StatelessWidget {
  final NoteEditorController controller;
  final VoidCallback onAddAttachment;

  const _NoteEditorContent({
    required this.controller,
    required this.onAddAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      keyboardDismissBehavior:
      ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        130,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 680,
          ),
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1B1D22)
                      : Colors.white,
                  borderRadius:
                  BorderRadius.circular(28),
                  border: Border.all(
                    color: colorScheme
                        .outlineVariant
                        .withValues(
                      alpha:
                      isDark ? 0.18 : 0.35,
                    ),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha:
                        isDark ? 0.15 : 0.05,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Title',
                      style: theme
                          .textTheme.labelLarge
                          ?.copyWith(
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller:
                      controller.titleController,
                      textCapitalization:
                      TextCapitalization.sentences,
                      textInputAction:
                      TextInputAction.next,
                      maxLength: 250,
                      decoration:
                      const InputDecoration(
                        hintText:
                        'Enter note title',
                        counterText: '',
                        prefixIcon: Icon(
                          CupertinoIcons.textformat,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Statement',
                      style: theme
                          .textTheme.labelLarge
                          ?.copyWith(
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller
                          .statementController,
                      textCapitalization:
                      TextCapitalization.sentences,
                      keyboardType:
                      TextInputType.multiline,
                      textInputAction:
                      TextInputAction.newline,
                      minLines: 10,
                      maxLines: null,
                      decoration:
                      const InputDecoration(
                        hintText:
                        'Write your note...',
                        alignLabelWithHint: true,
                        contentPadding:
                        EdgeInsets.all(17),
                      ),
                    ),
                    Obx(() {
                      final String error =
                      controller
                          .errorMessage.value
                          .trim();

                      if (error.isEmpty) {
                        return const SizedBox
                            .shrink();
                      }

                      return Padding(
                        padding:
                        const EdgeInsets.only(
                          top: 16,
                        ),
                        child: Container(
                          padding:
                          const EdgeInsets.all(
                            13,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme
                                .errorContainer
                                .withValues(
                              alpha: 0.70,
                            ),
                            borderRadius:
                            BorderRadius.circular(
                              16,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: <Widget>[
                              Icon(
                                CupertinoIcons
                                    .exclamationmark_circle,
                                color:
                                colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(
                                width: 9,
                              ),
                              Expanded(
                                child: Text(
                                  error,
                                  style: theme
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                    color: colorScheme
                                        .onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1B1D22)
                      : Colors.white,
                  borderRadius:
                  BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme
                        .outlineVariant
                        .withValues(
                      alpha:
                      isDark ? 0.18 : 0.35,
                    ),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: colorScheme.primary
                            .withValues(
                          alpha: 0.11,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          15,
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.photo,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Attachments',
                            style: theme
                                .textTheme.titleSmall
                                ?.copyWith(
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Add an image from camera or photos',
                            style: theme
                                .textTheme.bodySmall
                                ?.copyWith(
                              color: colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Obx(
                          () => IconButton(
                        tooltip: 'Add image',
                        onPressed: controller
                            .isSaving.value
                            ? null
                            : onAddAttachment,
                        icon: const Icon(
                          Icons.attach_file_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Obx(
                    () => FilledButton.icon(
                  onPressed:
                  controller.isSaving.value
                      ? null
                      : controller.saveChanges,
                  style: FilledButton.styleFrom(
                    minimumSize:
                    const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(19),
                    ),
                  ),
                  icon: controller.isSaving.value
                      ? SizedBox(
                    width: 21,
                    height: 21,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                        colorScheme.onPrimary,
                      ),
                    ),
                  )
                      : const Icon(
                    CupertinoIcons
                        .checkmark_alt,
                  ),
                  label: Text(
                    controller.isSaving.value
                        ? 'Saving...'
                        : 'Save Changes',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteEditorErrorState
    extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _NoteEditorErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.error
                    .withValues(alpha: 0.10),
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: 39,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Unable to load note',
              style: theme
                  .textTheme.titleLarge
                  ?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(
                color:
                colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}