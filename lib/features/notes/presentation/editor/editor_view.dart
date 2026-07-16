import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:notes/app/theme/app_colors.dart';
import 'package:notes/core/presentation/images/image_helper.dart';

import '../home/home_style.dart';
import 'editor_controller.dart';

part 'sheets/editor_action_sheets.dart';
part 'widgets/editor_bottom_bar.dart';
part 'widgets/editor_chrome.dart';
part 'widgets/integrated_image.dart';
part 'widgets/keyboard_accessory_bar.dart';
part 'widgets/tag_suggestions_bar.dart';

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
}
