import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

/// Shared settings app bar with an optional adaptive iOS back-button palette.
class SettingsSliverAppBar extends StatelessWidget {
  final String title;
  final bool useIosBackButtonColors;

  const SettingsSliverAppBar({
    super.key,
    required this.title,
    this.useIosBackButtonColors = false,
  });

  @override
  Widget build(BuildContext context) {
    final backButtonColor = useIosBackButtonColors
        ? CupertinoDynamicColor.resolve(CupertinoColors.systemBlue, context)
        : Colors.white;

    return AppScreenSliverAppBar(
      title: title,
      centerTitle: true,
      leading: CustomGlassButton(
        semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Get.back(),
        width: 44,
        height: 44,
        shape: GlassShape.circle,
        blur: 10,
        opacity: 0.15,
        thickness: 8,
        glassColor: useIosBackButtonColors
            ? null
            : IosSemanticColors.blue.withValues(alpha: 0.82),
        foregroundColor: backButtonColor,
        padding: EdgeInsets.zero,
        child: const Icon(CupertinoIcons.back, size: 23),
      ),
    );
  }
}
