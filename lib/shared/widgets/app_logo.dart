import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Canonical path of the app's brand mark.
///
/// A white silhouette carrying only an alpha channel, so it can be tinted at
/// render time and sits directly on any surface — there is no plate or ground
/// baked into the artwork.
const String kAppLogoAsset = 'assets/icons/piisiit_logo_mark.png';

/// The app's brand mark, tinted with the theme's pink.
///
/// Used wherever the app introduces itself — splash, sign in, sign up and
/// onboarding — so the brand reads the same at every entry point. The mark is
/// portrait, so [height] drives the layout and the width follows its natural
/// aspect ratio.
class AppLogo extends StatelessWidget {
  final double height;

  /// Defaults to the theme's primary pink, which differs between light and
  /// dark so the mark keeps its contrast either way.
  final Color? color;

  /// Adds a soft halo that follows the silhouette, for hero placements.
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

    // A blurred copy behind the mark, so the halo traces the silhouette
    // rather than the widget's bounding box.
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
