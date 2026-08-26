import 'dart:ui' as ui;

import 'package:flutter/material.dart';

const String kAppLogoAsset = 'assets/icons/piisiit_logo_mark.png';

class AppLogo extends StatelessWidget {
  final double height;

  final Color? color;

  final bool showGlow;

  const AppLogo({
    super.key,
    required this.height,
    this.color,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.primary;

    Widget mark(Color c) => Image.asset(
      kAppLogoAsset,
      height: height,
      color: c,
      colorBlendMode: BlendMode.srcIn,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      semanticLabel: 'Piisiit Note',
    );

    if (!showGlow) return mark(tint);

    return Stack(
      alignment: Alignment.center,
      children: [
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: height * 0.07,
            sigmaY: height * 0.07,
          ),
          child: mark(
            tint.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.55 : 0.35,
            ),
          ),
        ),
        mark(tint),
      ],
    );
  }
}
