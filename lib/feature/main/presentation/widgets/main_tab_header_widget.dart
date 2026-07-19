import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MainTabHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  final IconData? leadingIcon;
  final VoidCallback? onLeadingPressed;

  final VoidCallback? onRefresh;
  final VoidCallback? onAdd;

  final IconData addIcon;
  final Widget? trailing;

  final bool showLogo;
  final String logoAsset;

  const MainTabHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingIcon,
    this.onLeadingPressed,
    this.onRefresh,
    this.onAdd,
    this.addIcon = CupertinoIcons.add,
    this.trailing,
    this.showLogo = false,
    this.logoAsset = 'assets/icons/app_icon.png',
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color backgroundColor = isDark
        ? const Color(0xFF1B1D22).withValues(
      alpha: 0.90,
    )
        : Colors.white.withValues(
      alpha: 0.88,
    );

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          14,
          8,
          14,
          4,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(29),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 26,
              sigmaY: 26,
            ),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 74,
              ),
              padding: const EdgeInsets.fromLTRB(
                10,
                9,
                9,
                9,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(29),
                border: Border.all(
                  color: colorScheme.outlineVariant
                      .withValues(
                    alpha: isDark ? 0.23 : 0.40,
                  ),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.25 : 0.08,
                    ),
                    blurRadius: 28,
                    offset: const Offset(0, 11),
                  ),
                  BoxShadow(
                    color: colorScheme.primary.withValues(
                      alpha: isDark ? 0.05 : 0.035,
                    ),
                    blurRadius: 22,
                    offset: const Offset(-5, -4),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  if (leadingIcon != null)
                    _HeaderIconButton(
                      icon: leadingIcon!,
                      onPressed:
                      onLeadingPressed ?? () {},
                    )
                  else if (showLogo)
                    _HeaderLogo(
                      assetPath: logoAsset,
                    )
                  else
                    _HeaderPageIcon(
                      icon: _defaultIcon(),
                    ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme
                              .textTheme.titleLarge
                              ?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.45,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme
                              .textTheme.bodySmall
                              ?.copyWith(
                            color: colorScheme
                                .onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (trailing != null) ...<Widget>[
                    trailing!,
                    const SizedBox(width: 5),
                  ],

                  if (onRefresh != null) ...<Widget>[
                    _HeaderIconButton(
                      icon: CupertinoIcons.refresh,
                      tooltip: 'Refresh',
                      onPressed: onRefresh!,
                    ),
                    const SizedBox(width: 5),
                  ],

                  if (onAdd != null)
                    _HeaderIconButton(
                      icon: addIcon,
                      tooltip: 'Add',
                      highlighted: true,
                      onPressed: onAdd!,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _defaultIcon() {
    final String cleanTitle =
    title.trim().toLowerCase();

    if (cleanTitle.contains('folder')) {
      return CupertinoIcons.folder_fill;
    }

    if (cleanTitle.contains('note')) {
      return CupertinoIcons.doc_text_fill;
    }

    if (cleanTitle.contains('setting')) {
      return CupertinoIcons.gear_solid;
    }

    if (cleanTitle.contains('profile')) {
      return CupertinoIcons.person_fill;
    }

    if (cleanTitle.contains('delete') ||
        cleanTitle.contains('bin')) {
      return CupertinoIcons.delete_solid;
    }

    return CupertinoIcons.square_grid_2x2_fill;
  }
}

class MainTabHeaderAction extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onPressed;
  final bool highlighted;
  final bool destructive;
  final int? badgeCount;

  const MainTabHeaderAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.highlighted = false,
    this.destructive = false,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return _HeaderIconButton(
      icon: icon,
      tooltip: tooltip,
      highlighted: highlighted,
      destructive: destructive,
      badgeCount: badgeCount,
      onPressed: onPressed,
    );
  }
}

class _HeaderLogo extends StatelessWidget {
  final String assetPath;

  const _HeaderLogo({
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      width: 50,
      height: 50,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        color: colorScheme.surface,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (
              BuildContext context,
              Object error,
              StackTrace? stackTrace,
              ) {
            return Icon(
              CupertinoIcons.doc_text_fill,
              color: colorScheme.primary,
            );
          },
        ),
      ),
    );
  }
}

class _HeaderPageIcon extends StatelessWidget {
  final IconData icon;

  const _HeaderPageIcon({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        color: colorScheme.primary.withValues(
          alpha: 0.12,
        ),
        border: Border.all(
          color: colorScheme.primary.withValues(
            alpha: 0.15,
          ),
        ),
      ),
      child: Icon(
        icon,
        size: 23,
        color: colorScheme.primary,
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  final String? tooltip;
  final bool highlighted;
  final bool destructive;
  final int? badgeCount;

  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.highlighted = false,
    this.destructive = false,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color actionColor = destructive
        ? colorScheme.error
        : colorScheme.primary;

    final Color backgroundColor = highlighted
        ? actionColor
        : destructive
        ? colorScheme.error.withValues(
      alpha: 0.10,
    )
        : colorScheme.onSurface.withValues(
      alpha: isDark ? 0.075 : 0.055,
    );

    final Color foregroundColor = highlighted
        ? destructive
        ? colorScheme.onError
        : colorScheme.onPrimary
        : destructive
        ? colorScheme.error
        : colorScheme.onSurface;

    final Widget button = CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(
              milliseconds: 190,
            ),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border: Border.all(
                color: highlighted
                    ? actionColor
                    : destructive
                    ? colorScheme.error.withValues(
                  alpha: 0.20,
                )
                    : colorScheme.outlineVariant
                    .withValues(
                  alpha: isDark
                      ? 0.25
                      : 0.36,
                ),
              ),
              boxShadow: highlighted
                  ? <BoxShadow>[
                BoxShadow(
                  color: actionColor.withValues(
                    alpha: 0.30,
                  ),
                  blurRadius: 17,
                  offset: const Offset(0, 7),
                ),
              ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 20,
              color: foregroundColor,
            ),
          ),
          if (badgeCount != null &&
              badgeCount! > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: badgeCount! < 10
                      ? BoxShape.circle
                      : BoxShape.rectangle,
                  borderRadius: badgeCount! < 10
                      ? null
                      : BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeCount! > 99
                      ? '99+'
                      : badgeCount.toString(),
                  style: TextStyle(
                    color: colorScheme.onError,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (tooltip == null ||
        tooltip!.trim().isEmpty) {
      return button;
    }

    return Tooltip(
      message: tooltip!,
      child: button,
    );
  }
}