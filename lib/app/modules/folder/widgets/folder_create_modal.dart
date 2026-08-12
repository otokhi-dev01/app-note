import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/folder_model.dart';
import '../../../theme/app_theme.dart';
import '../controllers/folder_controller.dart';

/// Local controller to manage the creation/rename state and lifecycle.
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
    final initialName = folder?.name ?? '';
    folderName.value = initialName;
    nameController = TextEditingController(text: initialName);
    nameController.addListener(() => folderName.value = nameController.text);
    nameFocusNode = FocusNode();

    // Auto-focus after the transition
    Future.delayed(const Duration(milliseconds: 400), () {
      if (nameFocusNode.canRequestFocus) nameFocusNode.requestFocus();
    });
  }

  @override
  void onClose() {
    nameController.dispose();
    nameFocusNode.dispose();
    super.onClose();
  }

  Future<void> save() async {
    if (!canSave) return;
    FocusManager.instance.primaryFocus?.unfocus();
    isSaving.value = true;

    try {
      final success = await mainController.onSaveFolder(
        id: folder?.id ?? 0,
        name: folderName.value.trim(),
        iconName: folder?.iconName,
        colorValue: folder?.colorValue,
        sortOrder: folder?.sortOrder,
      );
      if (success) Get.back();
    } finally {
      isSaving.value = false;
    }
  }

  void cancel() {
    FocusManager.instance.primaryFocus?.unfocus();
    Get.back();
  }
}

class FolderCreateModal extends StatelessWidget {
  final FolderModel? folder;
  final FolderController controller;

  const FolderCreateModal({super.key, this.folder, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Initialize the local logic controller
    final c = Get.put(FolderCreateLogic(folder: folder, mainController: controller));
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    // UI logic: Full screen height handling keyboard
    return Scaffold(
      backgroundColor: _sheetColor(context),
      resizeToAvoidBottomInset: false, // We handle padding manually for immersion
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Column(
          children: [
            // Top Safe Area
            SizedBox(height: mediaQuery.padding.top),
            
            // Header Section
            _buildHeader(context, c),
            
            // Main Content Area (Full screen scrollable)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20, 
                  12, 
                  20, 
                  mediaQuery.viewInsets.bottom + 40, // Logic: Dynamic bottom padding to follow keyboard
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNameField(context, c),
                    const SizedBox(height: 20),
                    _buildSmartFolderRow(context, c),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FolderCreateLogic c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionButton(
            icon: CupertinoIcons.xmark,
            onTap: c.cancel,
            backgroundColor: _isDark(context) ? Colors.white12 : Colors.white,
          ),
          Text(
            c.isRenaming ? 'Rename Folder' : 'New Folder',
            style: TextStyle(
              color: _primaryTextColor(context), // Logic: Fixed color for visibility
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.4,
            ),
          ),
          Obx(() => _ActionButton(
                icon: CupertinoIcons.checkmark,
                onTap: c.canSave ? c.save : null,
                isLoading: c.isSaving.value,
                backgroundColor: c.canSave 
                    ? AppTheme.folderPink 
                    : AppTheme.folderPink.withValues(alpha: 0.4),
                iconColor: Colors.white,
              )),
        ],
      ),
    );
  }

  Widget _buildNameField(BuildContext context, FolderCreateLogic c) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorderColor(context), width: 0.5),
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
              style: TextStyle(
                color: _primaryTextColor(context),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Name',
                hintStyle: TextStyle(
                  color: _secondaryTextColor(context).withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Obx(() => c.folderName.value.isNotEmpty
              ? GestureDetector(
                  onTap: c.nameController.clear,
                  child: const Icon(CupertinoIcons.clear_circled_solid, color: Colors.grey, size: 20),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildSmartFolderRow(BuildContext context, FolderCreateLogic c) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorderColor(context), width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => c.folder != null ? c.mainController.onConvertToSmartFolder(c.folder!) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.folderPink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(CupertinoIcons.gear_alt, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Make Into Smart Folder',
                        style: TextStyle(
                          color: _primaryTextColor(context),
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Organize using tags and other filters',
                        style: TextStyle(
                          color: _secondaryTextColor(context),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.chevron_forward, color: Colors.grey, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  Color _sheetColor(BuildContext context) => _isDark(context) ? const Color(0xFF1C1C1E) : AppTheme.bodyColor;
  Color _cardColor(BuildContext context) => _isDark(context) ? const Color(0xFF2C2C2E) : AppTheme.cardColor;
  Color _primaryTextColor(BuildContext context) => _isDark(context) ? Colors.white : AppTheme.textPrimary;
  Color _secondaryTextColor(BuildContext context) => const Color(0xFF8E8E93);
  Color _cardBorderColor(BuildContext context) => _isDark(context) ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.72);
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color? iconColor;
  final bool isLoading;

  const _ActionButton({required this.icon, this.onTap, required this.backgroundColor, this.iconColor, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: isLoading
                ? const CupertinoActivityIndicator(color: Colors.white, radius: 8)
                : Icon(icon, color: iconColor ?? Colors.grey, size: 18),
          ),
        ),
      ),
    );
  }
}
