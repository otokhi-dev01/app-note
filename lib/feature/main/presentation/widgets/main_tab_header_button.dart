part of 'main_tab_header_widget.dart';

class _LiquidHeaderButton extends StatefulWidget {
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
  State<_LiquidHeaderButton> createState() {
    return _LiquidHeaderButtonState();
  }
}

class _LiquidHeaderButtonState extends State<_LiquidHeaderButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final double size = widget.compact ? 38 : 42;
    final Color accentColor = widget.destructive
        ? colorScheme.error
        : colorScheme.primary;
    final Color foregroundColor = _foregroundColor(colorScheme);
    final List<Color> buttonGradient = widget.highlighted
        ? <Color>[
            Color.lerp(accentColor, Colors.white, isDark ? 0.08 : 0.15) ??
                accentColor,
            accentColor,
          ]
        : <Color>[
            isDark
                ? Colors.white.withValues(alpha: 0.095)
                : Colors.white.withValues(alpha: 0.72),
            isDark
                ? Colors.white.withValues(alpha: 0.045)
                : colorScheme.surface.withValues(alpha: 0.55),
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
        minimumSize: Size.square(size),
        padding: EdgeInsets.zero,
        pressedOpacity: 1,
        onPressed: _handleTap,
        child: AnimatedScale(
          scale: _pressed ? 0.90 : 1,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: buttonGradient,
                  ),
                  border: Border.all(color: _borderColor(colorScheme, isDark)),
                  boxShadow: widget.highlighted
                      ? <BoxShadow>[
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.30),
                            blurRadius: 18,
                            spreadRadius: -3,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.15 : 0.045,
                            ),
                            blurRadius: 12,
                            spreadRadius: -5,
                            offset: const Offset(0, 5),
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
                          gradient: LinearGradient(
                            colors: <Color>[
                              Colors.transparent,
                              Colors.white.withValues(
                                alpha: widget.highlighted ? 0.40 : 0.28,
                              ),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      widget.icon,
                      size: widget.compact ? 18 : 19.5,
                      color: foregroundColor,
                    ),
                  ],
                ),
              ),
              if (widget.badgeCount != null && widget.badgeCount! > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: _HeaderBadge(count: widget.badgeCount!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _foregroundColor(ColorScheme colorScheme) {
    if (!widget.highlighted) {
      return widget.destructive ? colorScheme.error : colorScheme.onSurface;
    }

    return widget.destructive ? colorScheme.onError : colorScheme.onPrimary;
  }

  Color _borderColor(ColorScheme colorScheme, bool isDark) {
    if (widget.highlighted) {
      return Colors.white.withValues(alpha: isDark ? 0.17 : 0.32);
    }
    if (widget.destructive) {
      return colorScheme.error.withValues(alpha: 0.24);
    }

    return Colors.white.withValues(alpha: isDark ? 0.10 : 0.72);
  }

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
}
