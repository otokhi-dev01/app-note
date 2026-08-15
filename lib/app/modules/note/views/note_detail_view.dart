import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/glass_widgets.dart';
import '../../../theme/app_theme.dart';
import '../controllers/note_detail_controller.dart';
import '../widgets/note_content_editor.dart';
import '../widgets/note_detail_more_popup.dart';
import '../widgets/note_editor_toolbar.dart';
import '../widgets/note_editor_top_bar.dart';
import '../widgets/note_format_panel.dart';

class NoteDetailView extends GetView<NoteDetailController> {
  const NoteDetailView({super.key});

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
    final style = isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    return style.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
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
    final theme = Theme.of(context);

    Get.bottomSheet(
      Material(
        color: Colors.transparent,
        child: LiquidGlassContainer(
          borderRadius: 30,
          blur: 35,
          opacity: 0.1,
          thickness: 15,
          showGlow: true,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              _buildAction(
                context,
                CupertinoIcons.camera,
                'Take Photo or Video',
                () => controller.addAttachment(ImageSource.camera),
              ),
              _buildAction(
                context,
                CupertinoIcons.photo_on_rectangle,
                'Choose Photo or Video',
                () => controller.addAttachment(ImageSource.gallery),
              ),
              _buildAction(
                context,
                CupertinoIcons.pencil_outline,
                'Drawing',
                () => controller.startDrawing(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.folderPink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "CANCEL",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enterBottomSheetDuration: 400.ms,
    );
  }

  Widget _buildAction(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: AppTheme.folderPink, size: 24),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Get.back();
        onTap();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
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
