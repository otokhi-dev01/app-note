import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:notes/app/theme/colors.dart';
import '../home/home_style.dart';
import 'package:notes/core/utils/image_helper.dart';
import 'editor_controller.dart';

class EditorView extends GetView<EditorController> {
  const EditorView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Obx(
      () => PopScope(
        canPop: controller.canPop.value,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) controller.requestClose();
        },
        child: Theme(
          data: style.theme.copyWith(
            inputDecorationTheme: const InputDecorationTheme(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          child: Scaffold(
            backgroundColor: style.background,
            appBar: AppBar(
              backgroundColor: style.background,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: Center(
                child: _CircleButton(
                  onTap: controller.requestClose,
                  child: Icon(
                    CupertinoIcons.left_chevron,
                    color: style.primaryText,
                    size: 20,
                  ),
                ),
              ),
              actions: [
                _PillButton(
                  children: [
                    _ActionIconButton(
                      icon: CupertinoIcons.share,
                      onTap: controller.copyToClipboard,
                    ),
                    _ActionIconButton(
                      icon: CupertinoIcons.ellipsis,
                      onTap: () => _showMoreOptions(context),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Obx(
                  () => _CircleButton(
                    onTap: controller.isSaving.value
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            controller.save();
                          },
                    backgroundColor: style.theme.colorScheme.primary,
                    child: controller.isSaving.value
                        ? CupertinoActivityIndicator(
                            color: style.theme.colorScheme.onPrimary,
                            radius: 9,
                          )
                        : Icon(
                            CupertinoIcons.check_mark,
                            color: style.theme.colorScheme.onPrimary,
                            size: 18,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Form(
                      key: controller.formKey,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          Center(
                            child: Text(
                              DateFormat('MMMM d, yyyy \'at\' h:mm a').format(
                                controller.existingNote?.updatedAt ??
                                    DateTime.now(),
                              ),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: controller.titleController,
                            validator: controller.validateTitle,
                            autofocus: controller.existingNote == null,
                            style: TextStyle(
                              color: style.primaryText,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Title',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: controller.contentController,
                            focusNode: controller.contentFocusNode,
                            minLines: 10,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            style: TextStyle(
                              color: style.primaryText.withValues(alpha: 0.9),
                              fontSize: 19,
                              height: 1.5,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Notes',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),

                          Obx(
                            () => controller.imagePaths.isEmpty
                                ? const SizedBox.shrink()
                                : Padding(
                                    padding: const EdgeInsets.only(
                                      top: 20,
                                      bottom: 40,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: controller.imagePaths
                                          .asMap()
                                          .entries
                                          .map(
                                            (entry) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 20,
                                              ),
                                              child: _IntegratedImage(
                                                path: entry.value,
                                                onRemove: () => controller
                                                    .removeImage(entry.key),
                                                onEdit: () => controller
                                                    .editImage(entry.key),
                                                onTap: () => _showImageOptions(
                                                  context,
                                                  entry.key,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isKeyboardVisible) ...[
                    _FloatingKeyboardAccessoryBar(
                      onAddPhoto: () => _showAttachmentOptions(context),
                      onDraw: controller.openSketch,
                      onChecklist: controller.toggleChecklist,
                      onFormat: () => _showFormattingMenu(context),
                      onDone: () => FocusScope.of(context).unfocus(),
                    ),
                    _TagSuggestionsBar(onTagTap: controller.addTag),
                  ],
                ],
              ),
            ),
            bottomNavigationBar: isKeyboardVisible
                ? null
                : _ModernBottomBar(
                    onChecklist: controller.toggleChecklist,
                    onAttachment: () => _showAttachmentOptions(context),
                    onSketch: controller.openSketch,
                    onCompose: () {
                      controller.contentFocusNode.requestFocus();
                      HapticFeedback.lightImpact();
                    },
                  ),
          ),
        ),
      ),
    );
  }

  void _showFormattingMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Text Formatting'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              controller.applyInlineFormat('**', '**');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.bold),
                SizedBox(width: 12),
                Text('Bold'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              controller.applyInlineFormat('_', '_');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.italic),
                SizedBox(width: 12),
                Text('Italic'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              controller.applyLineFormat('> ');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.text_quote),
                SizedBox(width: 12),
                Text('Quote'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              controller.applyLineFormat('## ');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.textformat_size),
                SizedBox(width: 12),
                Text('Heading'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              controller.insertTable();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.table),
                SizedBox(width: 12),
                Text('Insert Table'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              Get.snackbar(
                "Note Options",
                "Pinning notes is not available in editor.",
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.pin),
                SizedBox(width: 8),
                Text('Pin Note'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              Get.snackbar(
                "Note Options",
                "Locking notes is not available yet.",
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.lock),
                SizedBox(width: 8),
                Text('Lock Note'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              Get.snackbar("Note Options", "Duplication is not available yet.");
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.doc_on_doc),
                SizedBox(width: 8),
                Text('Duplicate'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Get.back();
              controller.delete();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.trash),
                SizedBox(width: 8),
                Text('Delete'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showImageOptions(BuildContext context, int index) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Edit / Markup'),
            onPressed: () {
              Get.back();
              controller.editImage(index);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Replace from Gallery'),
            onPressed: () {
              Get.back();
              controller.replaceImage(index, ImageSource.gallery);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Replace from Camera'),
            onPressed: () {
              Get.back();
              controller.replaceImage(index, ImageSource.camera);
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: const Text('Remove Image'),
            onPressed: () {
              Get.back();
              controller.removeImage(index);
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

  void _showAttachmentOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add Attachment'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Take Photo or Video'),
            onPressed: () {
              Get.back();
              controller.addImage(ImageSource.camera);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Choose Photo or Video'),
            onPressed: () {
              Get.back();
              controller.addImage(ImageSource.gallery);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Scan Documents'),
            onPressed: () {
              Get.back();
              Get.snackbar(
                "Scan Documents",
                "Document scanning is not available.",
              );
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

class _CircleButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Color? backgroundColor;

  const _CircleButton({
    required this.onTap,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: backgroundColor ?? style.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: style.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final List<Widget> children;

  const _PillButton({required this.children});

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: style.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: style.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      onPressed: onTap,
      minimumSize: Size.zero,
      child: Icon(icon, color: style.secondaryText, size: 22),
    );
  }
}

class _IntegratedImage extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  final VoidCallback onEdit;
  final VoidCallback onTap;
  const _IntegratedImage({
    required this.path,
    required this.onRemove,
    required this.onEdit,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: Get.width * 0.8),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ImageHelper.buildSafeImage(
            path,
            width: double.infinity,
            radius: 12,
          ),
        ),
      ),
    );
  }
}

class _TagSuggestionsBar extends StatelessWidget {
  final Function(String) onTagTap;
  _TagSuggestionsBar({required this.onTagTap});

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return Container(
      height: 48,
      decoration: BoxDecoration(color: style.secondarySurface),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tags.length,
        separatorBuilder: (context, index) => Container(
          width: 0.5,
          margin: const EdgeInsets.symmetric(vertical: 12),
          color: style.border,
        ),
        itemBuilder: (context, index) => CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          onPressed: () => onTagTap(_tags[index]),
          child: Text(
            _tags[index],
            style: TextStyle(
              color: style.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  final List<String> _tags = [
    '#dinner',
    '#dessert',
    '#drink',
    '#pie',
    '#cooking',
    '#ideas',
    '#work',
    '#personal',
  ];
}

class _FloatingKeyboardAccessoryBar extends StatelessWidget {
  final VoidCallback onAddPhoto;
  final VoidCallback onDraw;
  final VoidCallback onChecklist;
  final VoidCallback onFormat;
  final VoidCallback onDone;

  const _FloatingKeyboardAccessoryBar({
    required this.onAddPhoto,
    required this.onDraw,
    required this.onChecklist,
    required this.onFormat,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      color: Colors.transparent,
      child: Center(
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: style.surface,
            borderRadius: BorderRadius.circular(27),
            boxShadow: [
              BoxShadow(
                color: style.shadow,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onFormat,
                child: Text(
                  'Aa',
                  style: TextStyle(
                    color: style.primaryText,
                    fontSize: 19,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              _AccessoryIcon(
                CupertinoIcons.list_bullet_indent,
                onTap: onChecklist,
              ),
              _AccessoryIcon(
                CupertinoIcons.table,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Get.snackbar(
                    "Table",
                    "Tables are not available in this version.",
                  );
                },
              ),
              _AccessoryIcon(CupertinoIcons.paperclip, onTap: onAddPhoto),
              _AccessoryIcon(CupertinoIcons.pencil_circle, onTap: onDraw),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onDone,
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: AppColors.magenta,
                    fontWeight: FontWeight.w600,
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

class _AccessoryIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _AccessoryIcon(this.icon, {this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap ?? () => HapticFeedback.lightImpact(),
      child: Icon(icon, color: style.primaryText, size: 22),
    );
  }
}

class _ModernBottomBar extends StatelessWidget {
  final VoidCallback onChecklist;
  final VoidCallback onAttachment;
  final VoidCallback onSketch;
  final VoidCallback onCompose;
  const _ModernBottomBar({
    required this.onChecklist,
    required this.onAttachment,
    required this.onSketch,
    required this.onCompose,
  });
  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return Container(
      decoration: BoxDecoration(
        color: style.background,
        border: Border(top: BorderSide(color: style.border, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  CupertinoIcons.list_bullet_indent,
                  color: AppColors.magenta,
                ),
                onPressed: onChecklist,
              ),
              IconButton(
                icon: const Icon(
                  CupertinoIcons.camera,
                  color: AppColors.magenta,
                ),
                onPressed: onAttachment,
              ),
              IconButton(
                icon: const Icon(
                  CupertinoIcons.pencil_outline,
                  color: AppColors.magenta,
                ),
                onPressed: onSketch,
              ),
              IconButton(
                icon: const Icon(
                  CupertinoIcons.square_pencil,
                  color: AppColors.magenta,
                ),
                onPressed: onCompose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
