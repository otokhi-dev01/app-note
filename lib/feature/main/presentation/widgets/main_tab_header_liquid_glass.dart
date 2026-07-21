part of 'main_tab_header_widget.dart';

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
    final bool isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 370;
        final bool veryCompact = constraints.maxWidth < 330;

        return ClipRRect(
          borderRadius: BorderRadius.circular(compact ? 25 : 28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: Container(
              constraints: BoxConstraints(minHeight: compact ? 66 : 72),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(compact ? 25 : 28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? <Color>[
                          const Color(0xFF25282F).withValues(alpha: 0.88),
                          const Color(0xFF17191E).withValues(alpha: 0.82),
                        ]
                      : <Color>[
                          Colors.white.withValues(alpha: 0.90),
                          Colors.white.withValues(alpha: 0.72),
                        ],
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.78),
                  width: 1,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.09),
                    blurRadius: 28,
                    spreadRadius: -5,
                    offset: const Offset(0, 13),
                  ),
                  BoxShadow(
                    color: colorScheme.primary.withValues(
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
                              alpha: isDark ? 0.20 : 0.90,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
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
                          _buildLeading(compact: compact),
                          SizedBox(width: compact ? 9 : 11),
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
                          SizedBox(width: compact ? 3 : 5),
                          trailing!,
                        ],
                        if (onRefresh != null) ...<Widget>[
                          SizedBox(width: compact ? 3 : 5),
                          MainTabHeaderAction(
                            icon: CupertinoIcons.refresh,
                            tooltip: 'Refresh',
                            compact: compact,
                            onPressed: onRefresh!,
                          ),
                        ],
                        if (onAdd != null) ...<Widget>[
                          SizedBox(width: compact ? 3 : 5),
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

  Widget _buildLeading({required bool compact}) {
    if (leadingIcon != null) {
      return MainTabHeaderAction(
        icon: leadingIcon!,
        tooltip: 'Back',
        compact: compact,
        onPressed: onLeadingPressed ?? () {},
      );
    }

    if (showLogo) {
      return _HeaderLogo(assetPath: logoAsset, compact: compact);
    }

    return _HeaderPageIcon(icon: _defaultIcon(), compact: compact);
  }

  IconData _defaultIcon() {
    final String normalizedTitle = title.trim().toLowerCase();

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
