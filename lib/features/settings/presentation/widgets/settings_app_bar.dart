import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

/// Settings app bar using the same blue glass treatment as Profile.
class SettingsSliverAppBar extends StatelessWidget {
  final String title;

  const SettingsSliverAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
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
        glassColor: IosSemanticColors.blue.withValues(alpha: 0.82),
        foregroundColor: Colors.white,
        padding: EdgeInsets.zero,
        child: const Icon(CupertinoIcons.chevron_left, size: 23),
      ),
    );
  }
}
