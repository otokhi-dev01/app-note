import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class LiquidBottomNavigation extends StatelessWidget {
  /// Continuous PageView position:
  ///
  /// 0.0 = Folders
  /// 1.0 = Notes
  /// 2.0 = Settings
  /// 3.0 = Profile
  final double page;

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onCreateNote;

  const LiquidBottomNavigation({
    super.key,
    required this.page,
    required this.selectedIndex,
    required this.onChanged,
    required this.onCreateNote,
  });

  static const int _pageCount = 4;

  @override
  Widget build(BuildContext context) {
    final double safePage = _safePage();

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        14,
        0,
        14,
        10,
      ),
      child: SizedBox(
        height: 70,
        child: Row(
          children: <Widget>[
            Expanded(
              child: _NavigationCapsule(
                page: safePage,
                selectedIndex: selectedIndex,
                onChanged: _selectPage,
              ),
            ),
            const SizedBox(width: 12),
            _CreateButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onCreateNote();
              },
            ),
          ],
        ),
      ),
    );
  }

  double _safePage() {
    if (!page.isFinite) {
      return selectedIndex
          .clamp(
        0,
        _pageCount - 1,
      )
          .toDouble();
    }

    return page
        .clamp(
      0.0,
      (_pageCount - 1).toDouble(),
    )
        .toDouble();
  }

  void _selectPage(int index) {
    if (index < 0 ||
        index >= _pageCount ||
        index == selectedIndex) {
      return;
    }

    HapticFeedback.selectionClick();
    onChanged(index);
  }
}

class _NavigationCapsule extends StatelessWidget {
  final double page;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _NavigationCapsule({
    required this.page,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isDark ? 0.28 : 0.09,
              ),
              blurRadius: 28,
              spreadRadius: -7,
              offset: const Offset(0, 11),
            ),
            BoxShadow(
              color: colorScheme.primary.withValues(
                alpha: isDark ? 0.07 : 0.035,
              ),
              blurRadius: 22,
              spreadRadius: -10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 30,
              sigmaY: 30,
            ),
            child: LayoutBuilder(
              builder: (
                  BuildContext context,
                  BoxConstraints constraints,
                  ) {
                return GestureDetector(
                  behavior:
                  HitTestBehavior.translucent,
                  onHorizontalDragStart: (
                      DragStartDetails details,
                      ) {
                    _selectFromPosition(
                      localX:
                      details.localPosition.dx,
                      width: constraints.maxWidth,
                    );
                  },
                  onHorizontalDragUpdate: (
                      DragUpdateDetails details,
                      ) {
                    _selectFromPosition(
                      localX:
                      details.localPosition.dx,
                      width: constraints.maxWidth,
                    );
                  },
                  child: SizedBox(
                    height: 70,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius:
                        BorderRadius.circular(33),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? <Color>[
                            const Color(
                              0xFF25272D,
                            ).withValues(
                              alpha: 0.84,
                            ),
                            const Color(
                              0xFF1B1D22,
                            ).withValues(
                              alpha: 0.88,
                            ),
                          ]
                              : <Color>[
                            Colors.white.withValues(
                              alpha: 0.80,
                            ),
                            const Color(
                              0xFFF1F1F4,
                            ).withValues(
                              alpha: 0.70,
                            ),
                          ],
                        ),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(
                            alpha: 0.11,
                          )
                              : Colors.white.withValues(
                            alpha: 0.88,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          const Positioned(
                            top: 0,
                            left: 20,
                            right: 20,
                            child: _CapsuleHighlight(),
                          ),

                          /*
                           * This widget now returns
                           * Positioned.fill directly under
                           * this Stack, fixing the crash.
                           */
                          _SelectedPill(
                            page: page,
                          ),

                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _NavigationItem(
                                  pageIndex: 0,
                                  page: page,
                                  selectedIndex:
                                  selectedIndex,
                                  label: 'folders'.tr,
                                  icon:
                                  CupertinoIcons.folder,
                                  selectedIcon:
                                  CupertinoIcons
                                      .folder_fill,
                                  onPressed: () {
                                    onChanged(0);
                                  },
                                ),
                              ),
                              Expanded(
                                child: _NavigationItem(
                                  pageIndex: 1,
                                  page: page,
                                  selectedIndex:
                                  selectedIndex,
                                  label: 'notes'.tr,
                                  icon:
                                  CupertinoIcons.doc_text,
                                  selectedIcon:
                                  CupertinoIcons
                                      .doc_text_fill,
                                  onPressed: () {
                                    onChanged(1);
                                  },
                                ),
                              ),
                              Expanded(
                                child: _NavigationItem(
                                  pageIndex: 2,
                                  page: page,
                                  selectedIndex:
                                  selectedIndex,
                                  label: 'settings'.tr,
                                  icon:
                                  CupertinoIcons.gear,
                                  selectedIcon:
                                  CupertinoIcons
                                      .gear_solid,
                                  onPressed: () {
                                    onChanged(2);
                                  },
                                ),
                              ),
                              Expanded(
                                child: _NavigationItem(
                                  pageIndex: 3,
                                  page: page,
                                  selectedIndex:
                                  selectedIndex,
                                  label: 'profile'.tr,
                                  icon:
                                  CupertinoIcons.person,
                                  selectedIcon:
                                  CupertinoIcons
                                      .person_fill,
                                  onPressed: () {
                                    onChanged(3);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _selectFromPosition({
    required double localX,
    required double width,
  }) {
    if (width <= 0) {
      return;
    }

    final double itemWidth = width / 4;

    final int index = (localX / itemWidth)
        .floor()
        .clamp(0, 3);

    if (index == selectedIndex) {
      return;
    }

    HapticFeedback.selectionClick();
    onChanged(index);
  }
}

class _SelectedPill extends StatelessWidget {
  final double page;

  const _SelectedPill({
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    /*
     * Positioned.fill is now the direct output of this
     * widget under the parent Stack.
     *
     * The inner Positioned is directly under the
     * inner Stack, so ParentDataWidget is valid.
     */
    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (
              BuildContext context,
              BoxConstraints constraints,
              ) {
            final ThemeData theme =
            Theme.of(context);

            final ColorScheme colorScheme =
                theme.colorScheme;

            final bool isDark =
                theme.brightness ==
                    Brightness.dark;

            final double itemWidth =
                constraints.maxWidth / 4;

            final double safePage =
            page.clamp(0.0, 3.0).toDouble();

            final double fraction =
                safePage - safePage.floor();

            final double liquidProgress =
            math.sin(
              fraction * math.pi,
            );

            final double baseWidth =
            math.max(
              50.0,
              itemWidth - 10,
            );

            final double maximumStretch =
            math.min(
              20.0,
              itemWidth * 0.18,
            );

            final double stretch =
                liquidProgress *
                    maximumStretch;

            final double pillWidth =
                baseWidth + stretch;

            final double left =
                (safePage * itemWidth) +
                    ((itemWidth - baseWidth) /
                        2) -
                    (stretch / 2);

            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(
                  left: left,
                  top: 6,
                  bottom: 6,
                  width: pillWidth,
                  child: Transform.scale(
                    scaleY:
                    1 -
                        (liquidProgress *
                            0.055),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius:
                        BorderRadius.circular(
                          27,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end:
                          Alignment.bottomRight,
                          colors: isDark
                              ? <Color>[
                            Colors.white
                                .withValues(
                              alpha: 0.14,
                            ),
                            Colors.white
                                .withValues(
                              alpha: 0.065,
                            ),
                          ]
                              : <Color>[
                            Colors.white
                                .withValues(
                              alpha: 0.98,
                            ),
                            Colors.white
                                .withValues(
                              alpha: 0.78,
                            ),
                          ],
                        ),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(
                            alpha: 0.13,
                          )
                              : Colors.white.withValues(
                            alpha: 0.96,
                          ),
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color:
                            Colors.black.withValues(
                              alpha:
                              isDark
                                  ? 0.18
                                  : 0.075,
                            ),
                            blurRadius: 18,
                            spreadRadius: -6,
                            offset:
                            const Offset(0, 7),
                          ),
                          BoxShadow(
                            color: colorScheme.primary
                                .withValues(
                              alpha:
                              isDark
                                  ? 0.07
                                  : 0.03,
                            ),
                            blurRadius: 12,
                            spreadRadius: -7,
                          ),
                        ],
                      ),
                      child: Align(
                        alignment:
                        const Alignment(
                          -0.25,
                          -0.72,
                        ),
                        child:
                        FractionallySizedBox(
                          widthFactor: 0.44,
                          heightFactor: 0.044,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white
                                  .withValues(
                                alpha:
                                isDark
                                    ? 0.18
                                    : 0.78,
                              ),
                              borderRadius:
                              BorderRadius.circular(
                                10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final int pageIndex;
  final double page;
  final int selectedIndex;

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  final VoidCallback onPressed;

  const _NavigationItem({
    required this.pageIndex,
    required this.page,
    required this.selectedIndex,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    final double distance =
    (page - pageIndex).abs();

    final double rawProgress =
    (1 - distance)
        .clamp(
      0.0,
      1.0,
    )
        .toDouble();

    final double progress =
    Curves.easeOutCubic.transform(
      rawProgress,
    );

    final bool selected =
        selectedIndex == pageIndex;

    final Color inactiveColor =
    colorScheme.onSurfaceVariant
        .withValues(alpha: 0.64);

    final Color activeColor =
        colorScheme.onSurface;

    final Color foregroundColor =
        Color.lerp(
          inactiveColor,
          activeColor,
          progress,
        ) ??
            inactiveColor;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        pressedOpacity: 0.52,
        onPressed: onPressed,
        child: LayoutBuilder(
          builder: (
              BuildContext context,
              BoxConstraints constraints,
              ) {
            final double availableLabelWidth =
            math.max(
              0.0,
              constraints.maxWidth - 39,
            );

            final double labelWidth =
                availableLabelWidth *
                    progress;

            return Row(
              mainAxisAlignment:
              MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Transform.scale(
                  scale:
                  0.95 +
                      (progress * 0.08),
                  child: Icon(
                    progress >= 0.5
                        ? selectedIcon
                        : icon,
                    size:
                    22 +
                        (progress * 1.5),
                    color: foregroundColor,
                  ),
                ),
                SizedBox(
                  width: 6 * progress,
                ),
                SizedBox(
                  width: labelWidth,
                  child: ClipRect(
                    child: Opacity(
                      opacity: progress,
                      child: Align(
                        alignment:
                        Alignment.centerLeft,
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          overflow:
                          TextOverflow.fade,
                          style: theme
                              .textTheme.labelLarge
                              ?.copyWith(
                            color:
                            foregroundColor,
                            fontSize: 12,
                            height: 1,
                            letterSpacing:
                            -0.18,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CreateButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    final ColorScheme colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness ==
            Brightness.dark;

    return Semantics(
      button: true,
      label: 'Create note',
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        pressedOpacity: 0.70,
        onPressed: onPressed,
        child: SizedBox(
          width: 64,
          height: 64,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end:
                Alignment.bottomRight,
                colors: <Color>[
                  Color.lerp(
                    colorScheme.primary,
                    Colors.white,
                    isDark ? 0.07 : 0.17,
                  ) ??
                      colorScheme.primary,
                  colorScheme.primary,
                  Color.lerp(
                    colorScheme.primary,
                    colorScheme.error,
                    0.10,
                  ) ??
                      colorScheme.primary,
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha:
                  isDark ? 0.20 : 0.66,
                ),
                width: 1.4,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colorScheme.primary
                      .withValues(
                    alpha: 0.38,
                  ),
                  blurRadius: 22,
                  spreadRadius: -3,
                  offset:
                  const Offset(0, 9),
                ),
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha:
                    isDark ? 0.26 : 0.12,
                  ),
                  blurRadius: 14,
                  spreadRadius: -5,
                  offset:
                  const Offset(0, 7),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Positioned(
                  top: 8,
                  left: 13,
                  right: 13,
                  child: SizedBox(
                    height: 9,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius:
                        BorderRadius.circular(
                          20,
                        ),
                        gradient:
                        LinearGradient(
                          colors: <Color>[
                            Colors.transparent,
                            Colors.white.withValues(
                              alpha: 0.40,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.add,
                  size: 30,
                  color:
                  colorScheme.onPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CapsuleHighlight extends StatelessWidget {
  const _CapsuleHighlight();

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return SizedBox(
      height: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Colors.transparent,
              Colors.white.withValues(
                alpha:
                isDark ? 0.16 : 0.90,
              ),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}