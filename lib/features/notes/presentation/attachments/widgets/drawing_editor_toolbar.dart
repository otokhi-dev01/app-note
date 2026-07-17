import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes/core/presentation/brand/app_brand.dart';
import 'package:notes/features/notes/presentation/attachments/controllers/drawing_editor_controller.dart';
import 'package:notes/features/notes/presentation/home/home_style.dart';

class DrawingEditorToolbar extends StatelessWidget {
  const DrawingEditorToolbar({
    super.key,
    required this.controller,
    required this.style,
    this.showTopBorder = false,
  });

  final DrawingEditorController controller;
  final HomeStyle style;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    return AppGlassSurface(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      opacity: style.isDark ? .82 : .88,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ColorPalette(controller: controller, style: style),
            const SizedBox(height: 10),
            _ToolActions(controller: controller, style: style),
          ],
        ),
      ),
    );
  }
}

class _ColorPalette extends StatelessWidget {
  const _ColorPalette({required this.controller, required this.style});

  final DrawingEditorController controller;
  final HomeStyle style;

  @override
  Widget build(BuildContext context) {
    final scheme = style.theme.colorScheme;
    final colors = <(String, Color)>[
      ('Black', Colors.black),
      ('White', Colors.white),
      ('Gray', const Color(0xFF8E8E93)),
      ('Red', const Color(0xFFFF453A)),
      ('Magenta', scheme.primary),
      ('Yellow', const Color(0xFFFFD60A)),
      ('Green', const Color(0xFF30D158)),
      ('Blue', const Color(0xFF0A84FF)),
      ('Purple', const Color(0xFFBF5AF2)),
      ('Pink', const Color(0xFFFF375F)),
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: colors.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          if (index == colors.length) {
            return Obx(() {
              final isCustom = !colors.any(
                (entry) => entry.$2 == controller.selectedColor.value,
              );
              return _CustomColorButton(
                selected: isCustom,
                accent: scheme.primary,
                surface: scheme.surface,
                onTap: () => controller.pickColor(context),
              );
            });
          }

          final entry = colors[index];
          return Obx(
            () => _ColorButton(
              label: entry.$1,
              color: entry.$2,
              selected: controller.selectedColor.value == entry.$2,
              accent: scheme.primary,
              outline: scheme.outlineVariant,
              onTap: () => controller.selectedColor.value = entry.$2,
            ),
          );
        },
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.accent,
    required this.outline,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final Color accent;
  final Color outline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label ink',
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 44,
            height: 44,
            padding: EdgeInsets.all(selected ? 3 : 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? accent : Colors.transparent,
                width: 2,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color == Colors.white
                      ? outline.withValues(alpha: .9)
                      : Colors.white.withValues(alpha: .28),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .12),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: selected
                  ? Icon(
                      CupertinoIcons.check_mark,
                      size: 15,
                      color: color.computeLuminance() > .55
                          ? Colors.black87
                          : Colors.white,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomColorButton extends StatelessWidget {
  const _CustomColorButton({
    required this.selected,
    required this.accent,
    required this.surface,
    required this.onTap,
  });

  final bool selected;
  final Color accent;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Custom ink color',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Custom color',
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? accent : Colors.transparent,
                width: 2,
              ),
            ),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Color(0xFFFF453A),
                    Color(0xFFFFD60A),
                    Color(0xFF30D158),
                    Color(0xFF0A84FF),
                    Color(0xFFBF5AF2),
                    Color(0xFFFF453A),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    selected ? CupertinoIcons.check_mark : CupertinoIcons.plus,
                    color: selected ? accent : null,
                    size: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolActions extends StatelessWidget {
  const _ToolActions({required this.controller, required this.style});

  final DrawingEditorController controller;
  final HomeStyle style;

  @override
  Widget build(BuildContext context) {
    final scheme = style.theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: .65),
              ),
            ),
            child: Obx(
              () => Row(
                children: [
                  Expanded(
                    child: _ToolChoice(
                      icon: CupertinoIcons.pencil,
                      label: 'Pen',
                      selected: controller.strokeWidth.value < 10,
                      scheme: scheme,
                      onTap: () => controller.strokeWidth.value = 5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _ToolChoice(
                      icon: CupertinoIcons.paintbrush,
                      label: 'Marker',
                      selected: controller.strokeWidth.value >= 10,
                      scheme: scheme,
                      onTap: () => controller.strokeWidth.value = 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Obx(
          () => _ActionButton(
            icon: CupertinoIcons.arrow_uturn_left,
            label: 'Undo',
            color: scheme.primary,
            background: scheme.surfaceContainer,
            outline: scheme.outlineVariant,
            onTap: controller.points.isEmpty ? null : controller.undoLastStroke,
          ),
        ),
        const SizedBox(width: 8),
        Obx(
          () => _ActionButton(
            icon: CupertinoIcons.trash,
            label: 'Clear drawing',
            color: scheme.error,
            background: scheme.surfaceContainer,
            outline: scheme.outlineVariant,
            onTap: controller.points.isEmpty ? null : controller.clearPoints,
          ),
        ),
      ],
    );
  }
}

class _ToolChoice extends StatelessWidget {
  const _ToolChoice({
    required this.icon,
    required this.label,
    required this.selected,
    required this.scheme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: .18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      color: selected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.outline,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final Color outline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(15),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: outline.withValues(alpha: .65)),
              ),
              child: Icon(
                icon,
                size: 21,
                color: enabled ? color : color.withValues(alpha: .32),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
