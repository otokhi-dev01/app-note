import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  final bool showLeading;
  final bool useSafeArea;

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
    this.showLeading = true,
    this.useSafeArea = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget header = Padding(
      padding: useSafeArea
          ? const EdgeInsets.fromLTRB(
        14,
        8,
        14,
        4,
      )
          : EdgeInsets.zero,
      child: _LiquidGlassHeader(
        title: title,
        subtitle: subtitle,
        leadingIcon: leadingIcon,
        onLeadingPressed: onLeadingPressed,
        onRefresh: onRefresh,
        onAdd: onAdd,
        addIcon: addIcon,
        trailing: trailing,
        showLogo: showLogo,
        logoAsset: logoAsset,
        showLeading: showLeading,
      ),
    );

    if (!useSafeArea) {
      return header;
    }

    return SafeArea(
      bottom: false,
      child: header,
    );
  }
}

class _LiquidGlassHeader extends StatelessWidget {
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
  final bool showLeading;

  const _LiquidGlassHeader({
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    required this.onLeadingPressed,
    required this.onRefresh,
    required this.onAdd,
    required this.addIcon,
    required this.trailing,
    required this.showLogo,
    required this.logoAsset,
    required this.showLeading,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark =
        theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (
          BuildContext context,
          BoxConstraints constraints,
          ) {
        final bool compact =
            constraints.maxWidth < 370;

        final bool veryCompact =
            constraints.maxWidth < 330;

        return ClipRRect(
          borderRadius: BorderRadius.circular(
            compact ? 25 : 28,
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 32,
              sigmaY: 32,
            ),
            child: Container(
              constraints: BoxConstraints(
                minHeight: compact ? 66 : 72,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  compact ? 25 : 28,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? <Color>[
                    const Color(0xFF25282F)
                        .withValues(
                      alpha: 0.88,
                    ),
                    const Color(0xFF17191E)
                        .withValues(
                      alpha: 0.82,
                    ),
                  ]
                      : <Color>[
                    Colors.white.withValues(
                      alpha: 0.90,
                    ),
                    Colors.white.withValues(
                      alpha: 0.72,
                    ),
                  ],
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(
                    alpha: 0.12,
                  )
                      : Colors.white.withValues(
                    alpha: 0.78,
                  ),
                  width: 1,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.30 : 0.09,
                    ),
                    blurRadius: 28,
                    spreadRadius: -5,
                    offset: const Offset(0, 13),
                  ),
                  BoxShadow(
                    color: colorScheme.primary
                        .withValues(
                      alpha: isDark ? 0.07 : 0.045,
                    ),
                    blurRadius: 26,
                    spreadRadius: -8,
                    offset: const Offset(-8, -7),
                  ),
                ],
              ),
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 18,
                    right: 18,
                    top: 0,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            Colors.transparent,
                            Colors.white.withValues(
                              alpha:
                              isDark ? 0.20 : 0.90,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Positioned(
                  //   top: -38,
                  //   right: 15,
                  //   child: IgnorePointer(
                  //     child: Container(
                  //       width: 105,
                  //       height: 75,
                  //       decoration: BoxDecoration(
                  //         shape: BoxShape.circle,
                  //         color: colorScheme.primary
                  //             .withValues(
                  //           alpha:
                  //           isDark ? 0.09 : 0.055,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 8 : 10,
                      compact ? 8 : 9,
                      compact ? 8 : 9,
                      compact ? 8 : 9,
                    ),
                    child: Row(
                      children: <Widget>[
                        if (showLeading) ...<Widget>[
                          _buildLeading(
                            context,
                            compact: compact,
                          ),
                          SizedBox(
                            width: compact ? 9 : 11,
                          ),
                        ],
                        Expanded(
                          child: _HeaderTitle(
                            title: title,
                            subtitle: subtitle,
                            compact: compact,
                            veryCompact: veryCompact,
                          ),
                        ),
                        if (trailing != null) ...<Widget>[
                          SizedBox(
                            width: compact ? 3 : 5,
                          ),
                          trailing!,
                        ],
                        if (onRefresh != null) ...<Widget>[
                          SizedBox(
                            width: compact ? 3 : 5,
                          ),
                          MainTabHeaderAction(
                            icon:
                            CupertinoIcons.refresh,
                            tooltip: 'Refresh',
                            compact: compact,
                            onPressed: onRefresh!,
                          ),
                        ],
                        if (onAdd != null) ...<Widget>[
                          SizedBox(
                            width: compact ? 3 : 5,
                          ),
                          MainTabHeaderAction(
                            icon: addIcon,
                            tooltip: 'Add',
                            highlighted: true,
                            compact: compact,
                            onPressed: onAdd!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeading(
      BuildContext context, {
        required bool compact,
      }) {
    if (leadingIcon != null) {
      return MainTabHeaderAction(
        icon: leadingIcon!,
        tooltip: 'Back',
        compact: compact,
        onPressed:
        onLeadingPressed ?? () {},
      );
    }

    if (showLogo) {
      return _HeaderLogo(
        assetPath: logoAsset,
        compact: compact,
      );
    }

    return _HeaderPageIcon(
      icon: _defaultIcon(),
      compact: compact,
    );
  }

  IconData _defaultIcon() {
    final String normalizedTitle =
    title.trim().toLowerCase();

    if (normalizedTitle.contains('folder')) {
      return CupertinoIcons.folder_fill;
    }

    if (normalizedTitle.contains('note')) {
      return CupertinoIcons.doc_text_fill;
    }

    if (normalizedTitle.contains('setting')) {
      return CupertinoIcons.gear_solid;
    }

    if (normalizedTitle.contains('profile')) {
      return CupertinoIcons.person_fill;
    }

    if (normalizedTitle.contains('delete') ||
        normalizedTitle.contains('bin') ||
        normalizedTitle.contains('trash')) {
      return CupertinoIcons.delete_solid;
    }

    if (normalizedTitle.contains('search')) {
      return CupertinoIcons.search;
    }

    return CupertinoIcons.square_grid_2x2_fill;
  }
}

class _HeaderTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool compact;
  final bool veryCompact;

  const _HeaderTitle({
    required this.title,
    required this.subtitle,
    required this.compact,
    required this.veryCompact,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool hasSubtitle =
        subtitle.trim().isNotEmpty;

    return Column(
      mainAxisAlignment:
      MainAxisAlignment.center,
      crossAxisAlignment:
      CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontSize: compact ? 18 : 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.55,
            height: 1.05,
          ),
        ),
        if (hasSubtitle &&
            !veryCompact) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color:
              colorScheme.onSurfaceVariant,
              fontSize: compact ? 10.5 : 11.5,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.08,
              height: 1.1,
            ),
          ),
        ],
      ],
    );
  }
}

class MainTabHeaderAction
    extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  final String? tooltip;
  final bool highlighted;
  final bool destructive;
  final int? badgeCount;
  final bool compact;

  const MainTabHeaderAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.highlighted = false,
    this.destructive = false,
    this.badgeCount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget button =
    _LiquidHeaderButton(
      icon: icon,
      onPressed: onPressed,
      highlighted: highlighted,
      destructive: destructive,
      badgeCount: badgeCount,
      compact: compact,
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

class _LiquidHeaderButton
    extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  final bool highlighted;
  final bool destructive;
  final int? badgeCount;
  final bool compact;

  const _LiquidHeaderButton({
    required this.icon,
    required this.onPressed,
    required this.highlighted,
    required this.destructive,
    required this.badgeCount,
    required this.compact,
  });

  @override
  State<_LiquidHeaderButton> createState() =>
      _LiquidHeaderButtonState();
}

class _LiquidHeaderButtonState
    extends State<_LiquidHeaderButton> {
  bool _pressed = false;

  void _updatePressed(bool value) {
    if (_pressed == value) {
      return;
    }

    setState(() {
      _pressed = value;
    });
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;
    final bool isDark =
        theme.brightness == Brightness.dark;

    final double size =
    widget.compact ? 38 : 42;

    final Color accentColor =
    widget.destructive
        ? colorScheme.error
        : colorScheme.primary;

    final Color foregroundColor =
    widget.highlighted
        ? widget.destructive
        ? colorScheme.onError
        : colorScheme.onPrimary
        : widget.destructive
        ? colorScheme.error
        : colorScheme.onSurface;

    final List<Color> buttonGradient =
    widget.highlighted
        ? <Color>[
      Color.lerp(
        accentColor,
        Colors.white,
        isDark ? 0.08 : 0.15,
      ) ??
          accentColor,
      accentColor,
    ]
        : <Color>[
      isDark
          ? Colors.white.withValues(
        alpha: 0.095,
      )
          : Colors.white.withValues(
        alpha: 0.72,
      ),
      isDark
          ? Colors.white.withValues(
        alpha: 0.045,
      )
          : colorScheme.surface
          .withValues(
        alpha: 0.55,
      ),
    ];

    return Listener(
      onPointerDown: (_) {
        _updatePressed(true);
      },
      onPointerUp: (_) {
        _updatePressed(false);
      },
      onPointerCancel: (_) {
        _updatePressed(false);
      },
      child: CupertinoButton(
        minSize: size,
        padding: EdgeInsets.zero,
        pressedOpacity: 1,
        onPressed: _handleTap,
        child: AnimatedScale(
          scale: _pressed ? 0.90 : 1,
          duration: const Duration(
            milliseconds: 130,
          ),
          curve: Curves.easeOutCubic,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 180,
                ),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: buttonGradient,
                  ),
                  border: Border.all(
                    color: widget.highlighted
                        ? Colors.white.withValues(
                      alpha: isDark
                          ? 0.17
                          : 0.32,
                    )
                        : widget.destructive
                        ? colorScheme.error
                        .withValues(
                      alpha: 0.24,
                    )
                        : Colors.white
                        .withValues(
                      alpha: isDark
                          ? 0.10
                          : 0.72,
                    ),
                  ),
                  boxShadow:
                  widget.highlighted
                      ? <BoxShadow>[
                    BoxShadow(
                      color: accentColor
                          .withValues(
                        alpha: 0.30,
                      ),
                      blurRadius: 18,
                      spreadRadius: -3,
                      offset:
                      const Offset(
                        0,
                        8,
                      ),
                    ),
                  ]
                      : <BoxShadow>[
                    BoxShadow(
                      color: Colors.black
                          .withValues(
                        alpha: isDark
                            ? 0.15
                            : 0.045,
                      ),
                      blurRadius: 12,
                      spreadRadius: -5,
                      offset:
                      const Offset(
                        0,
                        5,
                      ),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Positioned(
                      top: 5,
                      left: 9,
                      right: 9,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient:
                          LinearGradient(
                            colors: <Color>[
                              Colors.transparent,
                              Colors.white
                                  .withValues(
                                alpha:
                                widget.highlighted
                                    ? 0.40
                                    : 0.28,
                              ),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      widget.icon,
                      size: widget.compact
                          ? 18
                          : 19.5,
                      color: foregroundColor,
                    ),
                  ],
                ),
              ),
              if (widget.badgeCount != null &&
                  widget.badgeCount! > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: _HeaderBadge(
                    count: widget.badgeCount!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final int count;

  const _HeaderBadge({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    final String text =
    count > 99 ? '99+' : count.toString();

    final bool circular = count < 10;

    return Container(
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: circular ? 0 : 5,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.error,
        shape: circular
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: circular
            ? null
            : BorderRadius.circular(10),
        border: Border.all(
          color: theme.scaffoldBackgroundColor,
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.error.withValues(
              alpha: 0.30,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.onError,
          fontSize: 9,
          height: 1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeaderLogo extends StatelessWidget {
  final String assetPath;
  final bool compact;

  const _HeaderLogo({
    required this.assetPath,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;
    final bool isDark =
        theme.brightness == Brightness.dark;

    final double size = compact ? 44 : 48;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          compact ? 15 : 17,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withValues(
              alpha: isDark ? 0.12 : 0.92,
            ),
            colorScheme.surface.withValues(
              alpha: isDark ? 0.50 : 0.65,
            ),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: isDark ? 0.12 : 0.72,
          ),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.20 : 0.07,
            ),
            blurRadius: 14,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          compact ? 11 : 13,
        ),
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
              size: 22,
            );
          },
        ),
      ),
    );
  }
}

class _HeaderPageIcon
    extends StatelessWidget {
  final IconData icon;
  final bool compact;

  const _HeaderPageIcon({
    required this.icon,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;
    final bool isDark =
        theme.brightness == Brightness.dark;

    final double size = compact ? 44 : 48;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          compact ? 15 : 17,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colorScheme.primary.withValues(
              alpha: isDark ? 0.25 : 0.17,
            ),
            colorScheme.primary.withValues(
              alpha: isDark ? 0.10 : 0.075,
            ),
          ],
        ),
        border: Border.all(
          color: colorScheme.primary.withValues(
            alpha: isDark ? 0.22 : 0.18,
          ),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.primary.withValues(
              alpha: isDark ? 0.13 : 0.10,
            ),
            blurRadius: 17,
            spreadRadius: -5,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: 6,
            left: 10,
            right: 10,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.transparent,
                    Colors.white.withValues(
                      alpha: isDark ? 0.18 : 0.45,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Icon(
            icon,
            size: compact ? 21 : 23,
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}