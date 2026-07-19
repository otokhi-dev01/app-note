import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../folders/domain/entities/folder_entity.dart';
import '../../../main/presentation/widgets/app_liquid_background_widget.dart';
import '../controllers/create_note_controller.dart';

class CreateNoteView
    extends GetView<CreateNoteController> {
  const CreateNoteView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusManager.instance.primaryFocus
              ?.unfocus();
        },
        child: Stack(
          children: <Widget>[
            const Positioned.fill(
              child: AppLiquidBackgroundWidget(),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: <Widget>[
                  _CreateNoteNavigationBar(
                    onBack: () {
                      Get.back();
                    },
                    onCreate:
                    controller.createNote,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior
                          .onDrag,
                      physics:
                      const BouncingScrollPhysics(),
                      padding:
                      const EdgeInsets.fromLTRB(
                        16,
                        6,
                        16,
                        130,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                          const BoxConstraints(
                            maxWidth: 620,
                          ),
                          child: Column(
                            children: <Widget>[
                              const _NoteEditorCard(),
                              const SizedBox(
                                height: 14,
                              ),
                              const _MediaCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: SafeArea(
                top: false,
                child:
                const _CreateNoteBottomButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFolderPicker(
      BuildContext context,
      ) async {
    final List<FolderEntity> folders =
        controller.folders;

    if (folders.isEmpty) {
      final dynamic result =
      await Get.toNamed(
        AppRoutes.createFolder,
      );

      if (result == true) {
        await controller.loadFolders();
      }

      return;
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (
          BuildContext sheetContext,
          ) {
        return CupertinoActionSheet(
          title: const Text(
            'Choose Folder',
          ),
          message: const Text(
            'Select where this note will be saved.',
          ),
          actions: folders.map(
                (FolderEntity folder) {
              final bool selected =
                  controller
                      .selectedFolderId.value ==
                      folder.id;

              return CupertinoActionSheetAction(
                isDefaultAction: selected,
                onPressed: () {
                  controller.selectFolder(
                    folder.id,
                  );

                  Navigator.of(sheetContext).pop();
                },
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: <Widget>[
                    if (selected) ...<Widget>[
                      const Icon(
                        CupertinoIcons
                            .checkmark_circle_fill,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        folder.name.trim().isEmpty
                            ? 'Unnamed Folder'
                            : folder.name,
                      ),
                    ),
                  ],
                ),
              );
            },
          ).toList(),
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

  Future<void> _showMediaPicker(
      BuildContext context,
      ) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (
          BuildContext sheetContext,
          ) {
        return CupertinoActionSheet(
          title: const Text(
            'Add Image',
          ),
          message: const Text(
            'Take a new photo or choose images from your library.',
          ),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                controller.takePhoto();
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
                controller.choosePhotos();
              },
              child: const Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    CupertinoIcons.photo_on_rectangle,
                    size: 21,
                  ),
                  SizedBox(width: 9),
                  Text('Choose Photos'),
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
}

class _CreateNoteNavigationBar
    extends GetView<CreateNoteController> {
  final VoidCallback onBack;
  final Future<void> Function() onCreate;

  const _CreateNoteNavigationBar({
    required this.onBack,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        10,
        6,
        12,
        8,
      ),
      child: Row(
        children: <Widget>[
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: onBack,
            child: Icon(
              CupertinoIcons.back,
              color: colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'New Note',
                  style: theme
                      .textTheme.titleLarge
                      ?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'Capture your idea',
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
                () => CupertinoButton(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              onPressed:
              controller.isSaving.value
                  ? null
                  : onCreate,
              child: controller.isSaving.value
                  ? const SizedBox(
                width: 20,
                height: 20,
                child:
                CupertinoActivityIndicator(),
              )
                  : Text(
                'Create',
                style: TextStyle(
                  color:
                  colorScheme.primary,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteEditorCard
    extends GetView<CreateNoteController> {
  const _NoteEditorCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        20,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1B1D22)
            : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant
              .withValues(
            alpha: isDark ? 0.18 : 0.35,
          ),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.15 : 0.045,
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
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary
                      .withValues(alpha: 0.12),
                  borderRadius:
                  BorderRadius.circular(16),
                ),
                child: Icon(
                  CupertinoIcons
                      .square_pencil_fill,
                  color: colorScheme.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Create your note',
                      style: theme
                          .textTheme.titleMedium
                          ?.copyWith(
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Add a title and write your statement.',
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
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Folder',
            style:
            theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
                () => _FolderPickerButton(
              title:
              controller.selectedFolderName,
              isLoading:
              controller.isLoadingFolders.value,
              onPressed: () {
                final CreateNoteView? view =
                context
                    .findAncestorWidgetOfExactType<
                    CreateNoteView>();

                if (view != null) {
                  view._showFolderPicker(context);
                }
              },
            ),
          ),
          const SizedBox(height: 21),
          Text(
            'Title',
            style:
            theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
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
            decoration: const InputDecoration(
              hintText: 'Enter note title',
              prefixIcon: Icon(
                CupertinoIcons.textformat,
              ),
              counterText: '',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Statement',
            style:
            theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller:
            controller.statementController,
            textCapitalization:
            TextCapitalization.sentences,
            keyboardType:
            TextInputType.multiline,
            textInputAction:
            TextInputAction.newline,
            minLines: 7,
            maxLines: 14,
            decoration: const InputDecoration(
              hintText:
              'Write your note, idea, task, or statement...',
              alignLabelWithHint: true,
              contentPadding:
              EdgeInsets.all(17),
            ),
          ),
          Obx(() {
            final String error =
            controller.errorMessage.value.trim();

            if (error.isEmpty) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding:
              const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer
                      .withValues(alpha: 0.70),
                  borderRadius:
                  BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.error
                        .withValues(alpha: 0.20),
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      CupertinoIcons
                          .exclamationmark_circle,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        error,
                        style: theme
                            .textTheme.bodyMedium
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
    );
  }
}

class _FolderPickerButton
    extends StatelessWidget {
  final String title;
  final bool isLoading;
  final VoidCallback onPressed;

  const _FolderPickerButton({
    required this.title,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.44),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isLoading
            ? null
            : onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant
                  .withValues(alpha: 0.34),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primary
                      .withValues(alpha: 0.12),
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: Icon(
                  CupertinoIcons.folder_fill,
                  color: colorScheme.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: theme
                      .textTheme.titleSmall
                      ?.copyWith(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
              if (isLoading)
                const CupertinoActivityIndicator()
              else
                Icon(
                  CupertinoIcons
                      .chevron_down,
                  size: 18,
                  color: colorScheme
                      .onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaCard
    extends GetView<CreateNoteController> {
  const _MediaCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1B1D22)
            : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant
              .withValues(
            alpha: isDark ? 0.18 : 0.35,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Images',
                      style: theme
                          .textTheme.titleMedium
                          ?.copyWith(
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Obx(
                          () => Text(
                        controller
                            .selectedImages.isEmpty
                            ? 'Add camera or gallery images'
                            : '${controller.selectedImages.length} selected',
                        style: theme
                            .textTheme.bodySmall
                            ?.copyWith(
                          color: colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  final CreateNoteView? view =
                  context
                      .findAncestorWidgetOfExactType<
                      CreateNoteView>();

                  if (view != null) {
                    view._showMediaPicker(context);
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary
                        .withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    CupertinoIcons.add,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _MediaActionButton(
                  icon: CupertinoIcons.camera,
                  label: 'Camera',
                  onPressed:
                  controller.takePhoto,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MediaActionButton(
                  icon: CupertinoIcons
                      .photo_on_rectangle,
                  label: 'Photos',
                  onPressed:
                  controller.choosePhotos,
                ),
              ),
            ],
          ),
          Obx(() {
            final List<NoteDraftImage>
            imageSnapshot =
            controller.selectedImages.toList(
              growable: false,
            );

            if (imageSnapshot.isEmpty) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding:
              const EdgeInsets.only(top: 17),
              child: GridView.builder(
                shrinkWrap: true,
                physics:
                const NeverScrollableScrollPhysics(),
                itemCount: imageSnapshot.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 9,
                  crossAxisSpacing: 9,
                  childAspectRatio: 1,
                ),
                itemBuilder: (
                    BuildContext context,
                    int index,
                    ) {
                  if (index < 0 ||
                      index >=
                          imageSnapshot.length) {
                    return const SizedBox.shrink();
                  }

                  final NoteDraftImage image =
                  imageSnapshot[index];

                  return _SelectedImageTile(
                    image: image,
                    onRemove: () {
                      controller.removeImage(
                        image,
                      );
                    },
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MediaActionButton
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _MediaActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    return Material(
      color: colorScheme.primary
          .withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.primary
                  .withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 21,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme
                    .textTheme.labelLarge
                    ?.copyWith(
                  color: colorScheme.primary,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedImageTile
    extends StatelessWidget {
  final NoteDraftImage image;
  final VoidCallback onRemove;

  const _SelectedImageTile({
    required this.image,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: ClipRRect(
            borderRadius:
            BorderRadius.circular(17),
            child: Image.file(
              File(image.file.path),
              fit: BoxFit.cover,
              filterQuality:
              FilterQuality.medium,
              errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stackTrace,
                  ) {
                return Container(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  child: const Icon(
                    Icons.broken_image_outlined,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 30,
            onPressed: onRemove,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(
                  alpha: 0.68,
                ),
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateNoteBottomButton
    extends GetView<CreateNoteController> {
  const _CreateNoteBottomButton();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1B1D22)
            .withValues(alpha: 0.92)
            : Colors.white.withValues(
          alpha: 0.92,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: colorScheme.outlineVariant
              .withValues(
            alpha: isDark ? 0.22 : 0.40,
          ),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.28 : 0.10,
            ),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Obx(
            () => FilledButton.icon(
          onPressed:
          controller.isSaving.value
              ? null
              : controller.createNote,
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
                ? 'Creating Note...'
                : 'Create Note',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}