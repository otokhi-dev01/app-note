import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/core/theme/app_colors.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Local controller: manages text, appearance, save state, and lifecycle
// ─────────────────────────────────────────────────────────────────────────────
class FolderCreateLogic extends GetxController {
  final Folder? folder;
  final int? parentId;
  final FolderController mainController;

  FolderCreateLogic({this.folder, this.parentId, required this.mainController});

  late final TextEditingController nameController;
  late final FocusNode nameFocusNode;

  final folderName = ''.obs;
  final isSaving = false.obs;

  /// FEATURE: appearance the user picks, persisted as iconName / colorValue
  final iconName = FolderAppearance.defaultIconName.obs;
  final colorValue = FolderAppearance.defaultColorValue.obs;

  bool get isRenaming => folder != null;
  bool get canSave => folderName.value.trim().isNotEmpty && !isSaving.value;

  Color get color => FolderAppearance.parseHex(colorValue.value);
  IconData get icon => FolderAppearance.iconFor(iconName.value);

  @override
  void onInit() {
    super.onInit();
    final initialName = folder?.name ?? 'New Folder';
    folderName.value = initialName;
    nameController = TextEditingController(text: initialName);
    nameController.addListener(() => folderName.value = nameController.text);
    nameFocusNode = FocusNode();

    // Restore the folder's saved appearance when renaming, so reopening the
    // editor shows the swatch and glyph it was created with.
    iconName.value = FolderAppearance.normalizeIcon(folder?.iconName);
    colorValue.value = FolderAppearance.normalizeColor(folder?.colorValue);

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

  void selectColor(String value) {
    if (colorValue.value == value) return;
    HapticFeedback.selectionClick();
    colorValue.value = value;
  }

  void selectIcon(String value) {
    if (iconName.value == value) return;
    HapticFeedback.selectionClick();
    iconName.value = value;
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
        parentId: folder?.parentId ?? parentId,
        name: name,
        iconName: iconName.value,
        colorValue: colorValue.value,
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
  final Folder? folder;
  final int? parentId;
  final FolderController controller;

  const FolderCreateModal({
    super.key,
    this.folder,
    this.parentId,
    required this.controller,
  });

  @override
  State<FolderCreateModal> createState() => _FolderCreateModalState();
}

class _FolderCreateModalState extends State<FolderCreateModal>
    with SingleTickerProviderStateMixin {
  late final FolderCreateLogic _c;
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    final tag = widget.folder != null
        ? 'rename_${widget.folder!.id}'
        : (widget.parentId != null ? 'sub_${widget.parentId}' : 'create');
    _c = Get.put(
      FolderCreateLogic(
        folder: widget.folder,
        parentId: widget.parentId,
        mainController: widget.controller,
      ),
      tag: tag,
    );

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    // Start after the push transition so the stagger is actually visible.
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final colors = AppColors.of(context);
    final isDark = AppColors.isDark(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
      child: Scaffold(
        backgroundColor: colors.background,
        resizeToAvoidBottomInset: false, // We manage keyboard inset manually
        body: CustomGlassContainer(
          borderRadius: 0,
          blur: 40,
          opacity: 0.1,
          thickness: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top safe area ────────────────────────────────────
              SizedBox(height: mq.padding.top),

              // ── Header: [X]  Title  [✓] ──────────────────────────
              _buildHeader(context, _c, colors),

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
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _StaggerIn(
                            animation: _entrance,
                            index: 0,
                            child: _buildHeroPreview(context, _c, colors),
                          ),
                          const SizedBox(height: 28),
                          _StaggerIn(
                            animation: _entrance,
                            index: 1,
                            child: _buildSection(
                              context,
                              colors,
                              label: 'Name',
                              child: _buildNameField(context, _c, colors),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _StaggerIn(
                            animation: _entrance,
                            index: 2,
                            child: _buildSection(
                              context,
                              colors,
                              label: 'Color',
                              child: _buildColorPicker(context, _c, colors),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _StaggerIn(
                            animation: _entrance,
                            index: 3,
                            child: _buildSection(
                              context,
                              colors,
                              label: 'Icon',
                              child: _buildIconPicker(context, _c, colors),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _StaggerIn(
                            animation: _entrance,
                            index: 4,
                            child: _buildSmartFolderRow(context, _c, colors),
                          ),
                        ],
                      ),
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

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    FolderCreateLogic c,
    AppColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ✕ Cancel button
          CustomGlassButton(
            onPressed: c.cancel,
            semanticLabel: 'Cancel',
            width: 36,
            height: 36,
            shape: GlassShape.circle,
            opacity: 0.1,
            blur: 10,
            padding: EdgeInsets.zero,
            foregroundColor: colors.mutedIcon,
            child: const Icon(CupertinoIcons.xmark, size: 16),
          ),

          // Title
          Text(
            c.isRenaming ? 'Edit Folder' : 'New Folder',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: colors.primaryText,
            ),
          ),

          // ✓ Save button — tinted with the color the user picked
          Obx(() {
            final onAccent = AppColors.onAccent(c.color);
            return CustomGlassButton(
              onPressed: c.canSave ? c.save : null,
              semanticLabel: 'Save folder',
              width: 40,
              height: 40,
              shape: GlassShape.circle,
              opacity: c.canSave ? 0.8 : 0.2,
              thickness: 5,
              padding: EdgeInsets.zero,
              foregroundColor: onAccent,
              glassColor: c.color,
              child: c.isSaving.value
                  ? CupertinoActivityIndicator(color: onAccent, radius: 9)
                  : const Icon(CupertinoIcons.checkmark, size: 18),
            );
          }),
        ],
      ),
    );
  }

  // ── Hero preview: live rendering of the folder being built ──────────────────
  Widget _buildHeroPreview(
    BuildContext context,
    FolderCreateLogic c,
    AppColors colors,
  ) {
    final isDark = AppColors.isDark(context);

    return Obx(() {
      final color = c.color;
      final name = c.folderName.value.trim();

      return Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutCubic,
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(color, Colors.white, 0.3)!, color],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isDark ? 0.45 : 0.34),
                  blurRadius: 30,
                  spreadRadius: -4,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim.drive(CurveTween(curve: Curves.easeOutBack)),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                c.icon,
                key: ValueKey(c.iconName.value),
                color: AppColors.onAccent(color),
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            name.isEmpty ? 'New Folder' : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _previewSubtitle(c),
            style: TextStyle(color: colors.secondaryText, fontSize: 13.5),
          ),
        ],
      );
    });
  }

  String _previewSubtitle(FolderCreateLogic c) {
    if (c.isRenaming) {
      final count = c.folder!.noteCount;
      return 'Folder  •  $count ${count == 1 ? 'note' : 'notes'}';
    }
    if (c.parentId != null) {
      final parent = c.mainController.folders.firstWhereOrNull(
        (f) => f.id == c.parentId,
      );
      if (parent != null) return 'Subfolder of ${parent.name}';
    }
    return 'Folder  •  No notes yet';
  }

  // ── Grouped section wrapper: uppercase label + content ───────────────────────
  Widget _buildSection(
    BuildContext context,
    AppColors colors, {
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 9),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.9,
            ),
          ),
        ),
        child,
      ],
    );
  }

  // ── Name text field card ─────────────────────────────────────────────────────
  Widget _buildNameField(
    BuildContext context,
    FolderCreateLogic c,
    AppColors colors,
  ) {
    return Obx(
      () => CustomGlassTextField(
        controller: c.nameController,
        focusNode: c.nameFocusNode,
        placeholder: 'Name',
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => c.save(),
        height: 56,
        borderRadius: 18,
        textStyle: TextStyle(
          color: colors.primaryText,
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
        ),
        placeholderStyle: TextStyle(color: colors.placeholder, fontSize: 17),
        suffixIcon: c.folderName.value.isEmpty
            ? null
            : Icon(
                CupertinoIcons.clear_circled_solid,
                color: colors.mutedIcon,
                size: 20,
              ),
        onSuffixTap: c.folderName.value.isEmpty ? null : c.clearName,
      ),
    );
  }

  // ── FEATURE: color picker ────────────────────────────────────────────────────
  Widget _buildColorPicker(
    BuildContext context,
    FolderCreateLogic c,
    AppColors colors,
  ) {
    return CustomGlassContainer(
      borderRadius: 18,
      blur: 10,
      glassColor: colors.panelTint,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Obx(() {
        final selected = c.colorValue.value;
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 4,
          runSpacing: 10,
          children: [
            for (final hex in FolderAppearance.colors)
              _ColorSwatch(
                hex: hex,
                selected: selected == hex,
                onTap: () => c.selectColor(hex),
              ),
          ],
        );
      }),
    );
  }

  // ── FEATURE: icon picker ─────────────────────────────────────────────────────
  Widget _buildIconPicker(
    BuildContext context,
    FolderCreateLogic c,
    AppColors colors,
  ) {
    return CustomGlassContainer(
      borderRadius: 18,
      blur: 10,
      glassColor: colors.panelTint,
      padding: const EdgeInsets.all(14),
      child: Obx(() {
        final selectedIcon = c.iconName.value;
        final color = c.color;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: FolderAppearance.icons.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, i) {
            final option = FolderAppearance.icons[i];
            return _IconCell(
              option: option,
              accent: color,
              selected: option.name == selectedIcon,
              colors: colors,
              onTap: () => c.selectIcon(option.name),
            );
          },
        );
      }),
    );
  }

  // ── Smart Folder option row ──────────────────────────────────────────────────
  Widget _buildSmartFolderRow(
    BuildContext context,
    FolderCreateLogic c,
    AppColors colors,
  ) {
    return CustomGlassContainer(
      borderRadius: 18,
      blur: 10,
      glassColor: colors.panelTint,
      child: InkWell(
        onTap: () {
          if (c.folder != null) {
            c.mainController.onConvertToSmartFolder(c.folder!);
          }
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Obx(
                () => AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    CupertinoIcons.gear_alt_fill,
                    color: AppColors.onAccent(c.color),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Make Into Smart Folder',
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Organize using tags and other filters',
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_forward,
                color: colors.mutedIcon,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Building blocks
// ─────────────────────────────────────────────────────────────────────────────

/// A single tappable color circle with an animated selection ring.
class _ColorSwatch extends StatelessWidget {
  final String hex;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = FolderAppearance.parseHex(hex);

    return Semantics(
      button: true,
      selected: selected,
      label: 'Folder color $hex',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 46,
          height: 46,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: selected ? 1 : 0),
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            builder: (context, t, _) => Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: t,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                  ),
                ),
                Container(
                  width: 34 - 3 * t,
                  height: 34 - 3 * t,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4 * t),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Opacity(
                    opacity: t,
                    child: Icon(
                      CupertinoIcons.checkmark,
                      size: 16,
                      color: AppColors.onAccent(color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single tappable icon cell that fills with the picked accent when selected.
class _IconCell extends StatelessWidget {
  final FolderIconOption option;
  final Color accent;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  const _IconCell({
    required this.option,
    required this.accent,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: selected ? 1.06 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? accent : colors.cellFill,
              borderRadius: BorderRadius.circular(16),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.38),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              option.icon,
              size: 22,
              color: selected ? AppColors.onAccent(accent) : colors.cellIcon,
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades and lifts [child] into place on a delay derived from [index], so the
/// sections cascade in after the screen is pushed.
class _StaggerIn extends StatelessWidget {
  final Animation<double> animation;
  final int index;
  final Widget child;

  const _StaggerIn({
    required this.animation,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = math.min(index * 0.11, 0.5);
    final interval = Interval(
      start,
      math.min(start + 0.5, 1),
      curve: Curves.easeOut,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, inner) {
        final t = interval.transform(animation.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - t)),
            child: inner,
          ),
        );
      },
      child: child,
    );
  }
}
