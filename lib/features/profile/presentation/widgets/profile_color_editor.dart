import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/features/profile/presentation/widgets/profile_editor_controls.dart';

class ProfileColorEditor extends StatefulWidget {
  final String? initialColor;
  final ValueChanged<String> onSave;

  const ProfileColorEditor({
    super.key,
    required this.initialColor,
    required this.onSave,
  });

  @override
  State<ProfileColorEditor> createState() => _ProfileColorEditorState();
}

class _ProfileColorEditorState extends State<ProfileColorEditor> {
  late String? _selectedColor = widget.initialColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileEditorHeader(
            title: 'edit_color_title'.tr,
            subtitle: 'edit_color_subtitle'.tr,
            icon: CupertinoIcons.color_filter,
          ),
          const SizedBox(height: 20),
          Text(
            'color_label'.tr,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final hex in FolderAppearance.colors)
                _ProfileColorSwatch(
                  hex: hex,
                  selected: _selectedColor == hex,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedColor = hex);
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          ProfileEditorActions(
            onSave:
                _selectedColor == null || _selectedColor == widget.initialColor
                ? null
                : () {
                    widget.onSave(_selectedColor!);
                    Navigator.of(context).pop();
                  },
          ),
        ],
      ),
    );
  }
}

/// A selectable profile accent swatch.
class _ProfileColorSwatch extends StatelessWidget {
  final String hex;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileColorSwatch({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = FolderAppearance.parseHex(hex);
    return Semantics(
      label: FolderAppearance.colorNameFor(hex),
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: selected ? Colors.white : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: selected ? 0.5 : 0),
                blurRadius: 10,
              ),
            ],
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
              : null,
        ),
      ),
    );
  }
}
