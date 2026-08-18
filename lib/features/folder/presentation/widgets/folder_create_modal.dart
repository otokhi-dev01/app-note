import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/core/theme/app_colors.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/features/folder/presentation/widgets/folder_location_picker_modal.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Local controller: manages text, appearance, save state, and lifecycle
// ─────────────────────────────────────────────────────────────────────────────
class FolderCreateLogic extends GetxController {
  final Folder? folder;
  final int? parentId;
  final FolderController mainController;

  /// How to leave this screen once saved/cancelled. Defaults to popping back
  /// to the main Folder screen — the right call for every entry point except
  /// ones nested deeper in the stack (e.g. "New Folder" from the note-move
  /// picker), which pass their own callback so they land back where they
  /// were instead of being ejected all the way out.
  final VoidCallback? onDone;

  FolderCreateLogic({
    this.folder,
    this.parentId,
    required this.mainController,
    this.onDone,
  });

  late final TextEditingController nameController;
  late final FocusNode nameFocusNode;

  final folderName = ''.obs;
  final isSaving = false.obs;

  /// FEATURE: which folder this one nests under, `null` for the top level.
  /// Seeded from the folder being renamed, or the `parentId` this screen was
  /// opened with (e.g. "Create Subfolder"), and changeable via the Location
  /// picker either way.
  final selectedParentId = Rxn<int>();

  /// FEATURE: appearance the user picks, persisted as iconName / colorValue
  final iconName = FolderAppearance.defaultIconName.obs;
  final colorValue = FolderAppearance.defaultColorValue.obs;

  bool get isRenaming => folder != null;
  bool get canSave => folderName.value.trim().isNotEmpty && !isSaving.value;

  Color get color => FolderAppearance.parseHex(colorValue.value);
  IconData get icon => FolderAppearance.iconFor(iconName.value);

  /// The section keyword ('iCloud' / 'Shared' / '') baked into the folder
  /// being renamed, captured once up front so a rename can reapply it — the
  /// Name field only ever shows/edits the part the user actually typed.
  late final String _originalSectionKeyword = folder == null
      ? ''
      : mainController.sectionKeywordOf(folder!);

  @override
  void onInit() {
    super.onInit();
    final strippedName = folder == null
        ? ''
        : mainController.stripSectionKeyword(folder!.name);
    final initialName = folder == null
        ? 'New Folder'
        : (strippedName.isEmpty ? folder!.name : strippedName);
    folderName.value = initialName;
    nameController = TextEditingController(text: initialName);
    nameController.addListener(() => folderName.value = nameController.text);
    nameFocusNode = FocusNode();
    selectedParentId.value = folder?.parentId ?? parentId;

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

  void selectParent(int? id) {
    if (selectedParentId.value == id) return;
    selectedParentId.value = id;
  }

  /// The folder [selectedParentId] resolves to, or `null` at the top level.
  Folder? get parentFolder => selectedParentId.value == null
      ? null
      : mainController.folders.firstWhereOrNull(
          (f) => f.id == selectedParentId.value,
        );

  /// FEATURE: ✓ button tapped → save folder → navigate back to folder view
  Future<void> save() async {
    final typedName = folderName.value.trim();
    if (typedName.isEmpty || isSaving.value) return;

    // Reapply whichever section (Pii Cloud / Shared) the folder started in —
    // the Name field only ever showed the part the user typed, so nothing
    // they did there can silently knock it out of that section.
    final name = _originalSectionKeyword.isEmpty
        ? typedName
        : '$_originalSectionKeyword ${mainController.stripSectionKeyword(typedName)}'
              .trim();

    FocusManager.instance.primaryFocus?.unfocus();
    isSaving.value = true;

    try {
      // Reset controller isSaving in case it was stuck from a prior call
      mainController.isSaving.value = false;

      final success = await mainController.onSaveFolder(
        id: folder?.id ?? 0,
        parentId: selectedParentId.value,
        name: name,
        iconName: iconName.value,
        colorValue: colorValue.value,
        sortOrder: folder?.sortOrder,
      );

      if (success) {
        if (onDone != null) {
          onDone!();
        } else {
          // Pop back to the /folder route rather than a single Get.back():
          // this screen may sit under nested pushes (e.g. rename opened from
          // a subfolder several levels deep), and Get.until() unwinds all of
          // them in one go instead of leaving stragglers in the stack.
          Get.until((route) => route.settings.name == '/folder');
        }
      }
    } finally {
      isSaving.value = false;
    }
  }

  void cancel() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (onDone != null) {
      onDone!();
    } else {
      // Navigate back to folder view — same as save() for consistency
      Get.until((route) => route.settings.name == '/folder');
    }
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
  final VoidCallback? onDone;

  const FolderCreateModal({
    super.key,
    this.folder,
    this.parentId,
    required this.controller,
    this.onDone,
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
        onDone: widget.onDone,
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
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: GestureDetector(
          // Tap empty area to dismiss keyboard
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.opaque,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, _c, colors),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                sliver: SliverToBoxAdapter(
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
                          label: 'Location',
                          child: _buildLocationRow(context, _c, colors),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _StaggerIn(
                        animation: _entrance,
                        index: 3,
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
                        index: 4,
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
                        index: 5,
                        child: _buildSection(
                          context,
                          colors,
                          label: 'Emoji',
                          child: _buildEmojiPicker(context, _c, colors),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _StaggerIn(
                        animation: _entrance,
                        index: 6,
                        child: _buildSmartFolderRow(context, _c, colors),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: mq.padding.bottom + 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sliver app bar: collapsing large title, same language as Archive ────────
  Widget _buildAppBar(
    BuildContext context,
    FolderCreateLogic c,
    AppColors colors,
  ) {
    final theme = Theme.of(context);
    final label = c.isRenaming ? 'Edit Folder' : 'New Folder';

    return CustomGlassSliverAppBar(
      expandedHeight: 140,
      toolbarHeight: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      centerTitle: true,
      title: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
      ),
      leading: CustomGlassButton(
        onPressed: c.cancel,
        semanticLabel: 'Cancel',
        width: 44,
        height: 44,
        shape: GlassShape.circle,
        blur: 10,
        opacity: 0.15,
        thickness: 8,
        padding: EdgeInsets.zero,
        foregroundColor: colors.mutedIcon,
        child: const Icon(CupertinoIcons.xmark, size: 18),
      ),
      actions: [
        // ✓ Save button — tinted with the color the user picked
        Obx(() {
          final onAccent = AppColors.onAccent(c.color);
          return CustomGlassButton(
            onPressed: c.canSave ? c.save : null,
            semanticLabel: 'Save folder',
            width: 44,
            height: 44,
            shape: GlassShape.circle,
            blur: 10,
            opacity: c.canSave ? 0.8 : 0.2,
            thickness: 5,
            padding: EdgeInsets.zero,
            foregroundColor: onAccent,
            glassColor: c.color,
            child: c.isSaving.value
                ? CupertinoActivityIndicator(color: onAccent, radius: 9)
                : const Icon(CupertinoIcons.checkmark, size: 20),
          );
        }),
      ],
      largeTitleAlignment: Alignment.bottomLeft,
      largeTitlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
      largeTitle: Text(
        label,
        style: theme.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 34,
        ),
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
      final isEmoji = FolderAppearance.isEmoji(c.iconName.value);

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
              child: isEmoji
                  ? Text(
                      c.iconName.value,
                      key: ValueKey(c.iconName.value),
                      style: const TextStyle(fontSize: 42, height: 1),
                    )
                  : Icon(
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
    final parent = c.parentFolder;
    if (parent != null) return 'Subfolder of ${parent.displayName}';
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

  // ── FEATURE: Location row — iOS-Notes-style parent folder picker ────────────
  Widget _buildLocationRow(
    BuildContext context,
    FolderCreateLogic c,
    AppColors colors,
  ) {
    return CustomGlassContainer(
      borderRadius: 18,
      blur: 10,
      glassColor: colors.panelTint,
      child: InkWell(
        onTap: () => _pickLocation(context, c),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Obx(() {
            final parent = c.parentFolder;
            return Row(
              children: [
                parent != null
                    ? FolderGlyph(folder: parent, size: 22)
                    : Icon(
                        CupertinoIcons.device_phone_portrait,
                        color: colors.mutedIcon,
                        size: 22,
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    parent?.displayName ?? 'On My iPhone',
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_forward,
                  color: colors.mutedIcon,
                  size: 15,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Future<void> _pickLocation(BuildContext context, FolderCreateLogic c) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await Get.to<ParentSelection>(
      () => FolderLocationPickerModal(
        controller: c.mainController,
        currentParentId: c.selectedParentId.value,
        excludeFolderId: c.folder?.id,
      ),
      fullscreenDialog: true,
      transition: Transition.cupertino,
    );
    if (result != null) c.selectParent(result.parentId);
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

  // ── FEATURE: emoji picker (flutter_emoji) ────────────────────────────────────
  Widget _buildEmojiPicker(
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
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: FolderAppearance.emojis.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, i) {
            final emoji = FolderAppearance.emojis[i];
            return _EmojiCell(
              emoji: emoji,
              selected: emoji == selectedIcon,
              colors: colors,
              onTap: () => c.selectIcon(emoji),
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
          } else {
            AppSnackbar.info(
              'Save first',
              'Save this folder, then make it a Smart Folder from Edit Folder.',
            );
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

/// A single tappable emoji cell — same selection chrome as [_IconCell], but
/// the glyph itself needs no tint since emoji carry their own color.
class _EmojiCell extends StatelessWidget {
  final String emoji;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  const _EmojiCell({
    required this.emoji,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: emoji,
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
              color: colors.cellFill,
              borderRadius: BorderRadius.circular(16),
              border: selected
                  ? Border.all(color: colors.mutedIcon, width: 1.5)
                  : null,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
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
