import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../folders/domain/entities/folder_entity.dart';
import '../../../main/presentation/widgets/app_liquid_background_widget.dart';
import '../controllers/create_note_controller.dart';

class CreateNoteView extends GetView<CreateNoteController> {
  const CreateNoteView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: AppLiquidBackgroundWidget()),
          SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                _CreateNoteTopBar(
                  onBack: () {
                    FocusManager.instance.primaryFocus?.unfocus();

                    Get.back<void>();
                  },
                  onFolder: () {
                    _showFolderPicker(context);
                  },
                  onMore: () {
                    _showMoreActions(context);
                  },
                  onSave: controller.createNote,
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _FolderStatus(
                                onPressed: () {
                                  _showFolderPicker(context);
                                },
                              ),
                              const SizedBox(height: 20),
                              const _TitleField(),
                              const SizedBox(height: 8),
                              const _BodyField(),
                              const _ErrorMessage(),
                              _SelectedImagesSection(
                                onPreview: (NoteDraftImage image) {
                                  _openImagePreview(context, image);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _EditorToolbar(
                  onCamera: () async {
                    FocusManager.instance.primaryFocus?.unfocus();

                    await controller.takePhoto();
                  },
                  onPhotos: () async {
                    FocusManager.instance.primaryFocus?.unfocus();

                    await controller.choosePhotos();
                  },
                  onFolder: () {
                    _showFolderPicker(context);
                  },
                  onAddImage: () {
                    _showMediaPicker(context);
                  },
                  onDismissKeyboard: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFolderPicker(BuildContext context) async {
    final List<FolderEntity> folderSnapshot = List<FolderEntity>.unmodifiable(
      controller.folders.toList(),
    );

    if (folderSnapshot.isEmpty) {
      final dynamic result = await Get.toNamed(AppRoutes.createFolder);

      if (result == true) {
        await controller.loadFolders();
      }

      return;
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return Obx(() {
          final int? selectedFolderId = controller.selectedFolderId.value;

          return CupertinoActionSheet(
            title: const Text('Choose Folder'),
            message: const Text('Choose where this note will be saved.'),
            actions: folderSnapshot.map((FolderEntity folder) {
              final bool selected = selectedFolderId == folder.id;

              final String folderName = folder.name.trim().isEmpty
                  ? 'Unnamed Folder'
                  : folder.name.trim();

              return CupertinoActionSheetAction(
                isDefaultAction: selected,
                onPressed: () {
                  controller.selectFolder(folder.id);

                  Navigator.of(sheetContext).pop();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      selected
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.folder,
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        folderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
              },
              child: const Text('Cancel'),
            ),
          );
        });
      },
    );
  }

  Future<void> _showMediaPicker(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return CupertinoActionSheet(
          title: const Text('Add Image'),
          message: const Text('Take a picture or choose existing images.'),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(sheetContext).pop();

                await controller.takePhoto();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(CupertinoIcons.camera, size: 21),
                  SizedBox(width: 9),
                  Text('Take Picture'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(sheetContext).pop();

                await controller.choosePhotos();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(CupertinoIcons.photo_on_rectangle, size: 21),
                  SizedBox(width: 9),
                  Text('Choose Images'),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetContext).pop();
            },
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  Future<void> _showMoreActions(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return CupertinoActionSheet(
          title: const Text('New Note'),
          message: const Text('Choose an action.'),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();

                _showFolderPicker(context);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(CupertinoIcons.folder, size: 21),
                  SizedBox(width: 9),
                  Text('Choose Folder'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();

                _showMediaPicker(context);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(CupertinoIcons.photo, size: 21),
                  SizedBox(width: 9),
                  Text('Add Image'),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetContext).pop();
            },
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  Future<void> _openImagePreview(
    BuildContext context,
    NoteDraftImage image,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();

    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext previewContext) {
          return _ImagePreviewPage(image: image);
        },
      ),
    );
  }
}

class _CreateNoteTopBar extends GetView<CreateNoteController> {
  final VoidCallback onBack;
  final VoidCallback onFolder;
  final VoidCallback onMore;
  final Future<void> Function() onSave;

  const _CreateNoteTopBar({
    required this.onBack,
    required this.onFolder,
    required this.onMore,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: <Widget>[
          _GlassCircleButton(
            icon: CupertinoIcons.back,
            tooltip: 'Back',
            onPressed: onBack,
          ),
          const Spacer(),
          _GlassActionCapsule(
            children: <Widget>[
              _PlainActionButton(
                icon: CupertinoIcons.folder,
                tooltip: 'Folder',
                onPressed: onFolder,
              ),
              SizedBox(
                height: 23,
                child: VerticalDivider(
                  width: 1,
                  thickness: 0.7,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              _PlainActionButton(
                icon: CupertinoIcons.ellipsis,
                tooltip: 'More',
                onPressed: onMore,
              ),
            ],
          ),
          const SizedBox(width: 10),
          Obx(() {
            final bool saving = controller.isSaving.value;

            return _SaveCircleButton(
              isSaving: saving,
              onPressed: saving
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();

                      onSave();
                    },
            );
          }),
        ],
      ),
    );
  }
}

class _FolderStatus extends GetView<CreateNoteController> {
  final VoidCallback onPressed;

  const _FolderStatus({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Obx(() {
      final String folderName = controller.selectedFolderName.trim();

      final int imageCount = controller.selectedImages.length;

      return CupertinoButton(
        padding: EdgeInsets.zero,
        pressedOpacity: 0.55,
        onPressed: onPressed,
        child: Row(
          children: <Widget>[
            Icon(
              CupertinoIcons.folder_fill,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                folderName.isEmpty ? 'Choose a folder' : folderName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              CupertinoIcons.chevron_down,
              size: 13,
              color: colorScheme.onSurfaceVariant,
            ),
            if (imageCount > 0) ...<Widget>[
              const SizedBox(width: 14),
              Icon(
                CupertinoIcons.photo_fill,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                imageCount.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _TitleField extends GetView<CreateNoteController> {
  const _TitleField();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return TextField(
      controller: controller.titleController,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      maxLength: 250,
      minLines: 1,
      maxLines: 2,
      cursorColor: colorScheme.primary,
      style: theme.textTheme.headlineMedium?.copyWith(
        color: colorScheme.onSurface,
        fontSize: 31,
        height: 1.15,
        letterSpacing: -0.8,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        hintText: 'Title',
        hintStyle: theme.textTheme.headlineMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
          fontSize: 31,
          height: 1.15,
          letterSpacing: -0.8,
          fontWeight: FontWeight.w700,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        counterText: '',
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      onSubmitted: (_) {
        FocusScope.of(context).nextFocus();
      },
    );
  }
}

class _BodyField extends GetView<CreateNoteController> {
  const _BodyField();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return TextField(
      controller: controller.statementController,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      minLines: 13,
      maxLines: null,
      cursorColor: colorScheme.primary,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        fontSize: 18,
        height: 1.55,
        letterSpacing: -0.15,
      ),
      decoration: InputDecoration(
        hintText: 'Start writing your note…',
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.48),
          fontSize: 18,
          height: 1.55,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _ErrorMessage extends GetView<CreateNoteController> {
  const _ErrorMessage();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Obx(() {
      final String message = controller.errorMessage.value.trim();

      if (message.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.error.withValues(alpha: 0.20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  CupertinoIcons.exclamationmark_circle,
                  size: 20,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _SelectedImagesSection extends GetView<CreateNoteController> {
  final ValueChanged<NoteDraftImage> onPreview;

  const _SelectedImagesSection({required this.onPreview});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Obx(() {
      final List<NoteDraftImage> imageSnapshot =
          List<NoteDraftImage>.unmodifiable(controller.selectedImages.toList());

      if (imageSnapshot.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  CupertinoIcons.photo_fill,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Images',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '${imageSnapshot.length} selected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: imageSnapshot.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (BuildContext context, int index) {
                if (index < 0 || index >= imageSnapshot.length) {
                  return const SizedBox.shrink();
                }

                final NoteDraftImage image = imageSnapshot[index];

                return _SelectedImageTile(
                  key: ValueKey<String>(image.file.path),
                  image: image,
                  onPreview: () {
                    onPreview(image);
                  },
                  onRemove: () {
                    controller.removeImage(image);
                  },
                );
              },
            ),
          ],
        ),
      );
    });
  }
}

class _SelectedImageTile extends StatelessWidget {
  final NoteDraftImage image;
  final VoidCallback onPreview;
  final VoidCallback onRemove;

  const _SelectedImageTile({
    super.key,
    required this.image,
    required this.onPreview,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Material(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPreview,
              child: Image.file(
                File(image.file.path),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
              ),
            ),
          ),
        ),
        Positioned(
          left: 8,
          bottom: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              child: Row(
                children: <Widget>[
                  Icon(
                    CupertinoIcons.arrow_up_left_arrow_down_right,
                    color: Colors.white,
                    size: 12,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'View',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            pressedOpacity: 0.60,
            onPressed: onRemove,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.68),
              ),
              child: const SizedBox(
                width: 29,
                height: 29,
                child: Icon(
                  CupertinoIcons.xmark,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onPhotos;
  final VoidCallback onFolder;
  final VoidCallback onAddImage;
  final VoidCallback onDismissKeyboard;

  const _EditorToolbar({
    required this.onCamera,
    required this.onPhotos,
    required this.onFolder,
    required this.onAddImage,
    required this.onDismissKeyboard,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final bool isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 5, 16, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1B1D22).withValues(alpha: 0.90)
                    : Colors.white.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(27),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.white.withValues(alpha: 0.90),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.09),
                    blurRadius: 28,
                    spreadRadius: -8,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _ToolbarTextButton(
                      text: 'Aa',
                      tooltip: 'Text',
                      color: colorScheme.onSurface,
                      onPressed: onDismissKeyboard,
                    ),
                    _ToolbarButton(
                      icon: CupertinoIcons.folder,
                      tooltip: 'Folder',
                      onPressed: onFolder,
                    ),
                    _ToolbarButton(
                      icon: CupertinoIcons.camera,
                      tooltip: 'Take Picture',
                      onPressed: onCamera,
                    ),
                    _ToolbarButton(
                      icon: CupertinoIcons.photo_on_rectangle,
                      tooltip: 'Choose Images',
                      onPressed: onPhotos,
                    ),
                    _ToolbarButton(
                      icon: CupertinoIcons.paperclip,
                      tooltip: 'Add Image',
                      highlighted: true,
                      onPressed: onAddImage,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool highlighted;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        pressedOpacity: 0.52,
        onPressed: () {
          HapticFeedback.selectionClick();

          onPressed();
        },
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            size: highlighted ? 25 : 23,
            color: highlighted ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ToolbarTextButton extends StatelessWidget {
  final String text;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  const _ToolbarTextButton({
    required this.text,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        pressedOpacity: 0.52,
        onPressed: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w500,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreviewPage extends StatelessWidget {
  final NoteDraftImage image;

  const _ImagePreviewPage({required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(80),
              child: Center(
                child: Image.file(
                  File(image.file.path),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white70,
                              size: 50,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Unable to display image',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        );
                      },
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  _DarkPreviewButton(
                    icon: CupertinoIcons.xmark,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const Spacer(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0x66000000),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        'Pinch to zoom',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkPreviewButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _DarkPreviewButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0x88000000),
        ),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _GlassCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            pressedOpacity: 0.55,
            onPressed: onPressed,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF1B1D22).withValues(alpha: 0.78)
                    : Colors.white.withValues(alpha: 0.82),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.white.withValues(alpha: 0.92),
                ),
              ),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Icon(icon, size: 25, color: theme.colorScheme.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassActionCapsule extends StatelessWidget {
  final List<Widget> children;

  const _GlassActionCapsule({required this.children});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1B1D22).withValues(alpha: 0.78)
                : Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.92),
            ),
          ),
          child: SizedBox(
            height: 52,
            child: Row(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }
}

class _PlainActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _PlainActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        pressedOpacity: 0.55,
        onPressed: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            size: 23,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _SaveCircleButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback? onPressed;

  const _SaveCircleButton({required this.isSaving, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      pressedOpacity: 0.72,
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onPressed == null
              ? colorScheme.primary.withValues(alpha: 0.46)
              : colorScheme.primary,
          boxShadow: onPressed == null
              ? null
              : <BoxShadow>[
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.30),
                    blurRadius: 18,
                    spreadRadius: -4,
                    offset: const Offset(0, 7),
                  ),
                ],
        ),
        child: SizedBox(
          width: 54,
          height: 54,
          child: Center(
            child: isSaving
                ? CupertinoActivityIndicator(color: colorScheme.onPrimary)
                : Icon(
                    CupertinoIcons.check_mark,
                    size: 28,
                    color: colorScheme.onPrimary,
                  ),
          ),
        ),
      ),
    );
  }
}
