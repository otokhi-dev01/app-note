import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/folder_model.dart';
import '../../../theme/app_theme.dart';
import '../controllers/folder_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Local controller: manages text, save state, and lifecycle
// ─────────────────────────────────────────────────────────────────────────────
class FolderCreateLogic extends GetxController {
  final FolderModel? folder;
  final FolderController mainController;

  FolderCreateLogic({this.folder, required this.mainController});

  late final TextEditingController nameController;
  late final FocusNode nameFocusNode;

  final folderName = ''.obs;
  final isSaving = false.obs;

  bool get isRenaming => folder != null;
  bool get canSave => folderName.value.trim().isNotEmpty && !isSaving.value;

  @override
  void onInit() {
    super.onInit();
    final initialName = folder?.name ?? 'New Folder';
    folderName.value = initialName;
    nameController = TextEditingController(text: initialName);
    nameController.addListener(() => folderName.value = nameController.text);
    nameFocusNode = FocusNode();

    // Auto-focus + select all text after screen transition completes
    Future.delayed(const Duration(milliseconds: 380), () {
      if (nameFocusNode.canRequestFocus) {
        nameFocusNode.requestFocus();
        // Select all text so user can immediately start typing a new name
        nameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: nameController.text.length,
        );
      }
    });
  }

  @override
  void onClose() {
    nameController.dispose();
    nameFocusNode.dispose();
    super.onClose();
  }

  /// FEATURE: ✓ button tapped → save folder → navigate back to folder view
  Future<void> save() async {
    final name = folderName.value.trim();
    if (name.isEmpty || isSaving.value) return;

    FocusManager.instance.primaryFocus?.unfocus();
    isSaving.value = true;

    try {
      // Reset controller isSaving in case it was stuck from a prior call
      mainController.isSaving.value = false;

      final success = await mainController.onSaveFolder(
        id: folder?.id ?? 0,
        name: name,
        iconName: folder?.iconName,
        colorValue: folder?.colorValue,
        sortOrder: folder?.sortOrder,
      );

      if (success) {
        // Use Get.until() to pop back to /folder route.
        // This is more reliable than Get.back() when snackbars are showing,
        // because Get.back() can accidentally dismiss the snackbar overlay instead.
        Get.until((route) => route.settings.name == '/folder');
      }
    } finally {
      isSaving.value = false;
    }
  }

  void cancel() {
    FocusManager.instance.primaryFocus?.unfocus();
    // Navigate back to folder view — same as save() for consistency
    Get.until((route) => route.settings.name == '/folder');
  }

  void clearName() {
    nameController.clear();
    nameFocusNode.requestFocus();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main screen widget
// ─────────────────────────────────────────────────────────────────────────────
class FolderCreateModal extends StatefulWidget {
  final FolderModel? folder;
  final FolderController controller;

  const FolderCreateModal({super.key, this.folder, required this.controller});

  @override
  State<FolderCreateModal> createState() => _FolderCreateModalState();
}

class _FolderCreateModalState extends State<FolderCreateModal> {
  late final FolderCreateLogic _c;

  @override
  void initState() {
    super.initState();
    final tag = widget.folder != null ? 'rename_${widget.folder!.id}' : 'create';
    _c = Get.put(
      FolderCreateLogic(folder: widget.folder, mainController: widget.controller),
      tag: tag,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : AppTheme.bodyColor,
      resizeToAvoidBottomInset: false, // We manage keyboard inset manually
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top safe area ────────────────────────────────────
          SizedBox(height: mq.padding.top),

          // ── Header: [X]  Title  [✓] ──────────────────────────
          _buildHeader(context, _c, isDark),

          // ── Scrollable content, keyboard-aware ───────────────
          Expanded(
            child: GestureDetector(
              // Tap empty area to dismiss keyboard
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.opaque,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  bottom: mq.viewInsets.bottom > 0
                      ? mq.viewInsets.bottom + 16
                      : mq.padding.bottom + 16,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      _buildNameField(context, _c, isDark),
                      const SizedBox(height: 16),
                      _buildSmartFolderRow(context, _c, isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, FolderCreateLogic c, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ✕ Cancel button — always tappable, clears screen on tap
          _CircleButton(
            size: 36,
            backgroundColor: isDark ? Colors.white12 : Colors.white,
            onTap: c.cancel, // → unfocus + Get.back() → back to folder view
            child: Icon(
              CupertinoIcons.xmark,
              size: 16,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),

          // Title
          Text(
            c.isRenaming ? 'Rename Folder' : 'New Folder',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),

          // ✓ Save button — pink circle, saves folder then clears screen
          Obx(() => _CircleButton(
                size: 40,
                backgroundColor: c.canSave
                    ? AppTheme.folderPink
                    : AppTheme.folderPink.withValues(alpha: 0.35),
                onTap: c.save, // guard is inside save() — only acts when canSave
                child: c.isSaving.value
                    ? const CupertinoActivityIndicator(color: Colors.white, radius: 9)
                    : const Icon(CupertinoIcons.checkmark, size: 18, color: Colors.white),
              )),
        ],
      ),
    );
  }

  // ── Name text field card ─────────────────────────────────────────────────────
  Widget _buildNameField(BuildContext context, FolderCreateLogic c, bool isDark) {
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: c.nameController,
              focusNode: c.nameFocusNode,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => c.save(),
              cursorColor: AppTheme.folderPink,
              cursorWidth: 2,
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.2,
              ),
              decoration: InputDecoration(
                hintText: 'Name',
                hintStyle: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.3),
                  fontSize: 17,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          // Clear (×) button — visible only when there is text
          Obx(() => c.folderName.value.isNotEmpty
              ? GestureDetector(
                  onTap: c.clearName,
                  child: Icon(
                    CupertinoIcons.clear_circled_solid,
                    color: isDark ? Colors.white38 : Colors.black26,
                    size: 20,
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  // ── Smart Folder option row ──────────────────────────────────────────────────
  Widget _buildSmartFolderRow(BuildContext context, FolderCreateLogic c, bool isDark) {
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final primaryText = isDark ? Colors.white : Colors.black;
    final secondaryText = isDark ? Colors.white54 : Colors.black45;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: () {
            if (c.folder != null) {
              c.mainController.onConvertToSmartFolder(c.folder!);
            }
          },
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Pink rounded square with gear icon
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.folderPink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(CupertinoIcons.gear_alt_fill, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Make Into Smart Folder',
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Organize using tags and other filters',
                        style: TextStyle(color: secondaryText, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_forward,
                  color: isDark ? Colors.white30 : Colors.black26,
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable animated circular button
// Uses Material+InkWell so taps are never swallowed by parent GestureDetectors
// ─────────────────────────────────────────────────────────────────────────────
class _CircleButton extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Widget child;
  final VoidCallback? onTap;

  const _CircleButton({
    required this.size,
    required this.backgroundColor,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Center(child: child),
        ),
      ),
    );
  }
}
