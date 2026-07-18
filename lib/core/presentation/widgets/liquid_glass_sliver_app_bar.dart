import 'package:flutter/material.dart';

import '../brand/app_brand.dart';

typedef LiquidGlassAppBarLeadingBuilder =
    Widget? Function(BuildContext context);

class LiquidGlassSliverAppBar extends StatelessWidget {
  const LiquidGlassSliverAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions = const [],
    this.height = 56,
    this.blur = 18,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.padding,
    this.tint,
  });

  final Widget? title;
  final LiquidGlassAppBarLeadingBuilder? leading;
  final List<Widget> actions;

  /// Collapsed height.
  final double height;

  final double blur;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.zero,
      sliver: SliverToBoxAdapter(
        child: SizedBox(
          height: height,
          child: _AppBarContent(
            title: title,
            leading: leading?.call(context),
            actions: actions,
            borderRadius: borderRadius,
            blur: blur,
            padding: padding,
            tint: tint,
          ),
        ),
      ),
    );
  }
}

class _AppBarContent extends StatelessWidget {
  const _AppBarContent({
    required this.title,
    required this.leading,
    required this.actions,
    required this.borderRadius,
    required this.blur,
    required this.padding,
    required this.tint,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget> actions;
  final BorderRadius borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SizedBox(
      height: 56,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: AppGlassSurface(
            borderRadius: borderRadius,
            blur: blur,
            opacity: theme.brightness == Brightness.dark ? 0.72 : 0.78,
            tint: tint,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 10),
            hasShadow: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) leading!,
                if (leading != null) const SizedBox(width: 4),
                Expanded(
                  child: DefaultTextStyle(
                    style:
                        theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: colors.onSurface,
                        ) ??
                        TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: colors.onSurface,
                        ),
                    child: title ?? const SizedBox(),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
