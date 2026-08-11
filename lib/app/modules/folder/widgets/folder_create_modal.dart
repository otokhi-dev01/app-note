import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/folder_model.dart';
import '../../../theme/app_theme.dart';
import '../controllers/folder_controller.dart';

class FolderCreateModal extends StatefulWidget {
  final FolderModel? folder;
  final FolderController controller;

  const FolderCreateModal({super.key, this.folder, required this.controller});

  @override
  State<FolderCreateModal> createState() => _FolderCreateModalState();
}

class _FolderCreateModalState extends State<FolderCreateModal> {
  static const String _displayFont = 'CupertinoSystemDisplay';
  static const String _textFont = 'CupertinoSystemText';
  static const double _maxContentWidth = 600;

  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;
  late String _folderName;
  bool _isSaving = false;

  bool get _isRenaming => widget.folder != null;
  bool get _canSave => _folderName.isNotEmpty && !_isSaving;

  @override
  void initState() {
    super.initState();
    _folderName = widget.folder?.name ?? 'New Folder';
    _nameController = TextEditingController(text: _folderName);
    _nameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _folderName.length,
    );
    _nameController.addListener(_handleNameChanged);
    _nameFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_handleNameChanged)
      ..dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _handleNameChanged() {
    if (_folderName == _nameController.text) return;
    setState(() => _folderName = _nameController.text);
  }

  Future<void> _saveFolder() async {
    if (!_canSave) return;

    // Dismiss keyboard immediately
    FocusScope.of(context).unfocus();

    // If renaming and name hasn't changed, just close
    if (_isRenaming && _folderName.trim() == widget.folder!.name.trim()) {
      Get.back<void>();
      return;
    }

    setState(() => _isSaving = true);

    try {
      final folder = widget.folder;
      final success = await widget.controller.onSaveFolder(
        id: folder?.id ?? 0,
        name: _folderName.trim(),
        iconName: folder?.iconName,
        colorValue: folder?.colorValue,
        sortOrder: folder?.sortOrder,
      );

      if (!mounted) return;

      if (success) {
        // Use closeAllSnackbars if needed, but here we just want to close the bottom sheet
        Get.back<void>();
      } else {
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topGap = mediaQuery.padding.top.clamp(12.0, 72.0);
    final sheetHeight = mediaQuery.size.height - topGap;
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final horizontalInset = (mediaQuery.size.width * 0.05).clamp(16.0, 24.0);

    return SizedBox(
      height: sheetHeight,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Material(
          color: _sheetColor(context),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(bottom: keyboardInset),
            child: SafeArea(
              top: false,
              bottom: keyboardInset == 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    horizontalInset,
                    18,
                    horizontalInset,
                    24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _maxContentWidth,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 12),
                        _buildNameField(context),
                        const SizedBox(height: 14),
                        _buildSmartFolderRow(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final growth = (scale - 1).clamp(0.0, 1.0);
    final controlSize =
        38 + (growth * 10); // Slightly smaller as seen in screenshot

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _RoundActionButton(
                key: const ValueKey('close-folder-modal-button'),
                size: controlSize,
                semanticLabel: 'Close',
                onTap: () => Get.back<void>(),
                backgroundColor: Colors.white,
                borderColor: AppTheme.dividerColor.withValues(alpha: 0.3),
                shadowColor: Colors.black.withValues(alpha: 0.04),
                child: const Icon(
                  CupertinoIcons.xmark,
                  color: Colors.black,
                  size: 18,
                ),
              ),
            ),
            Text(
              _isRenaming ? 'Rename Folder' : 'New Folder',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontFamily: _displayFont,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.4,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _RoundActionButton(
                key: const ValueKey('save-folder-button'),
                size: controlSize,
                semanticLabel: _isRenaming
                    ? 'Save folder name'
                    : 'Create folder',
                onTap: _canSave ? _saveFolder : null,
                backgroundColor: _canSave
                    ? AppTheme.folderPink
                    : AppTheme.folderPink.withValues(alpha: 0.4),
                borderColor: Colors.white.withValues(alpha: 0.2),
                shadowColor: AppTheme.folderPink.withValues(
                  alpha: _canSave ? 0.2 : 0,
                ),
                child: _isSaving
                    ? const CupertinoActivityIndicator(
                        color: Colors.white,
                        radius: 8,
                      )
                    : const Icon(
                        CupertinoIcons.checkmark,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final growth = (scale - 1).clamp(0.0, 1.0);
    final fieldHeight = 48 + (growth * 10);

    return Semantics(
      textField: true,
      label: _isRenaming ? 'Folder name' : 'New folder name',
      child: Container(
        height: fieldHeight,
        decoration: BoxDecoration(
          color: _cardColor(context),
          borderRadius: BorderRadius.circular(fieldHeight / 2),
          border: Border.all(color: _cardBorderColor(context), width: 0.5),
        ),
        child: TextSelectionTheme(
          data: TextSelectionThemeData(
            cursorColor: AppTheme.folderPink,
            selectionColor: AppTheme.folderPink.withValues(alpha: 0.28),
            selectionHandleColor: AppTheme.folderPink,
          ),
          child: TextField(
            key: const ValueKey('folder-name-field'),
            controller: _nameController,
            focusNode: _nameFocusNode,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveFolder(),
            cursorColor: AppTheme.folderPink,
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(
              color: _primaryTextColor(context),
              fontFamily: _textFont,
              fontSize: 17,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.25,
              height: 1.15,
            ),
            decoration: InputDecoration(
              hintText: 'Name',
              hintStyle: TextStyle(
                color: _secondaryTextColor(context),
                fontFamily: _textFont,
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
              contentPadding: const EdgeInsets.only(left: 16, right: 6),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 44,
              ),
              suffixIcon: _folderName.isEmpty
                  ? null
                  : Semantics(
                      button: true,
                      label: 'Clear folder name',
                      child: CupertinoButton(
                        key: const ValueKey('clear-folder-name-button'),
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onPressed: _nameController.clear,
                        child: Icon(
                          CupertinoIcons.clear_circled_solid,
                          color: _clearIconColor(context),
                          size: 18,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartFolderRow(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Make Into Smart Folder',
      hint: 'Organize using tags and other filters',
      child: Material(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            final folder = widget.folder;
            if (folder != null) {
              widget.controller.onConvertToSmartFolder(folder);
            }
          },
          excludeFromSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 66),
            padding: const EdgeInsets.fromLTRB(18, 8, 16, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _cardBorderColor(context), width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.folderPink,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    CupertinoIcons.gear_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Make Into Smart Folder',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _primaryTextColor(context),
                          fontFamily: _textFont,
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.25,
                          height: 1.18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Organize using tags and other filters',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _secondaryTextColor(context),
                          fontFamily: _textFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.1,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  CupertinoIcons.chevron_forward,
                  color: _chevronColor(context),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _sheetColor(BuildContext context) {
    return _isDark(context) ? const Color(0xFF1C1C1E) : AppTheme.bodyColor;
  }

  Color _cardColor(BuildContext context) {
    return _isDark(context) ? const Color(0xFF2C2C2E) : AppTheme.cardColor;
  }

  Color _primaryTextColor(BuildContext context) {
    return _isDark(context) ? Colors.white : AppTheme.textPrimary;
  }

  Color _secondaryTextColor(BuildContext context) {
    return _isDark(context) ? const Color(0xFF98989D) : const Color(0xFF7C7C80);
  }

  Color _cardBorderColor(BuildContext context) {
    return _isDark(context)
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.72);
  }

  Color _clearIconColor(BuildContext context) {
    return _isDark(context) ? const Color(0xFF636366) : const Color(0xFFC7C7CC);
  }

  Color _chevronColor(BuildContext context) {
    return _isDark(context) ? const Color(0xFF636366) : const Color(0xFFC7C7CC);
  }
}

class _RoundActionButton extends StatelessWidget {
  final double size;
  final String semanticLabel;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final Widget child;

  const _RoundActionButton({
    super.key,
    required this.size,
    required this.semanticLabel,
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.shadowColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Material(
              color: backgroundColor,
              child: InkWell(
                onTap: onTap,
                excludeFromSemantics: true,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: 0.5),
                  ),
                  child: Center(child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
