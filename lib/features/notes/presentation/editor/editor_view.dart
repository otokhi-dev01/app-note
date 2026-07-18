import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:notes/core/presentation/brand/app_brand.dart';
import 'package:notes/core/presentation/images/image_helper.dart';
import '../home/home_style.dart';
import 'editor_controller.dart';
part 'sheets/editor_action_sheets.dart';
part 'widgets/editor_bottom_bar.dart';
part 'widgets/editor_chrome.dart';
part 'widgets/integrated_image.dart';
part 'widgets/statement_composer.dart';

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
          child: AppBrandBackdrop(
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              extendBody: true,
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  Positioned.fill(
                    child: SafeArea(
                      bottom: false,
                      child: Form(
                        key: controller.formKey,
                        child: ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(22, 64, 22, 104),
                          children: [
                            Center(
                              child: Text(
                                DateFormat('MMMM d, yyyy \'at\' h:mm a').format(
                                  controller.existingNote?.updatedAt ??
                                      DateTime.now(),
                                ),
                                style: TextStyle(
                                  color: style.secondaryText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              key: const ValueKey('note_title_field'),
                              controller: controller.titleController,
                              focusNode: controller.titleFocusNode,
                              validator: controller.validateTitle,
                              autofocus: controller.existingNote == null,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  controller.focusFirstStatement(),
                              style: TextStyle(
                                color: style.primaryText,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                                height: 1.15,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Title',
                                hintStyle: TextStyle(
                                  color: style.secondaryText.withValues(
                                    alpha: .68,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _StatementComposer(
                              controller: controller,
                              onImageOptions: (imageIndex) =>
                                  _showImageOptions(context, imageIndex),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: controller.focusContent,
                              child: const SizedBox(height: 120),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _ModernBottomBar(
                      keyboardVisible: isKeyboardVisible,
                      onFormat: () => _showFormattingMenu(context),
                      onDone: () => FocusScope.of(context).unfocus(),
                      onChecklist: controller.toggleChecklist,
                      onAttachment: () => _showAttachmentOptions(
                        context,
                        afterStatement: controller.activeStatementIndex.value,
                      ),
                      onSketch: controller.openSketch,
                      onCompose: () {
                        controller.focusContent();
                        HapticFeedback.lightImpact();
                      },
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Obx(
                      () => _EditorTopBar(
                        onClose: controller.requestClose,
                        onSave: controller.save,
                        isSaving: controller.isSaving.value,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
