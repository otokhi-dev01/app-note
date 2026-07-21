part of 'liquid_bottom_navigation_widget.dart';

class _NotchedNavigationBar extends StatefulWidget {
  final double page;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onCreateNote;

  const _NotchedNavigationBar({
    required this.page,
    required this.selectedIndex,
    required this.onChanged,
    required this.onCreateNote,
  });

  @override
  State<_NotchedNavigationBar> createState() {
    return _NotchedNavigationBarState();
  }
}

class _NotchedNavigationBarState extends State<_NotchedNavigationBar> {
  static const int _itemCount = 4;
  static const double _centerGap = 86;

  int? _activePointer;
  int? _lastDragIndex;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (PointerDownEvent event) {
            if (_activePointer != null) {
              return;
            }

            _activePointer = event.pointer;
            _lastDragIndex = widget.selectedIndex;
            _updateSelectedIndex(
              xPosition: event.localPosition.dx,
              navigationWidth: width,
            );
          },
          onPointerMove: (PointerMoveEvent event) {
            if (_activePointer != event.pointer) {
              return;
            }

            _updateSelectedIndex(
              xPosition: event.localPosition.dx,
              navigationWidth: width,
            );
          },
          onPointerUp: (PointerUpEvent event) {
            if (_activePointer != event.pointer) {
              return;
            }

            _resetActivePointer();
          },
          onPointerCancel: (PointerCancelEvent event) {
            if (_activePointer != event.pointer) {
              return;
            }

            _resetActivePointer();
          },
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                top: 18,
                bottom: 0,
                child: PhysicalShape(
                  clipper: const _NotchedBarClipper(),
                  clipBehavior: Clip.antiAlias,
                  color: colors.surface,
                  shadowColor: colors.shadow.withValues(
                    alpha: isDark ? 0.34 : 0.16,
                  ),
                  elevation: isDark ? 10 : 14,
                  child: CustomPaint(
                    foregroundPainter: _NotchedBarBorderPainter(
                      color: colors.outlineVariant.withValues(
                        alpha: isDark ? 0.45 : 0.60,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 5),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: _buildNavigationItem(
                                    pageIndex: 0,
                                    label: 'folders'.tr,
                                    icon: CupertinoIcons.folder,
                                    selectedIcon: CupertinoIcons.folder_fill,
                                  ),
                                ),
                                Expanded(
                                  child: _buildNavigationItem(
                                    pageIndex: 1,
                                    label: 'notes'.tr,
                                    icon: CupertinoIcons.doc_text,
                                    selectedIcon: CupertinoIcons.doc_text_fill,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: _centerGap),
                          Expanded(
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: _buildNavigationItem(
                                    pageIndex: 2,
                                    label: 'settings'.tr,
                                    icon: CupertinoIcons.gear,
                                    selectedIcon: CupertinoIcons.gear_solid,
                                  ),
                                ),
                                Expanded(
                                  child: _buildNavigationItem(
                                    pageIndex: 3,
                                    label: 'profile'.tr,
                                    icon: CupertinoIcons.person,
                                    selectedIcon: CupertinoIcons.person_fill,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: _CreateNoteButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onCreateNote();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationItem({
    required int pageIndex,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
  }) {
    return _NavigationItem(
      pageIndex: pageIndex,
      page: widget.page,
      selected: widget.selectedIndex == pageIndex,
      label: label,
      icon: icon,
      selectedIcon: selectedIcon,
      onAccessibilityTap: () {
        _selectFromAccessibility(pageIndex);
      },
    );
  }

  void _resetActivePointer() {
    _activePointer = null;
    _lastDragIndex = null;
  }

  void _updateSelectedIndex({
    required double xPosition,
    required double navigationWidth,
  }) {
    if (navigationWidth <= 0) {
      return;
    }

    final int index = _nearestTabIndex(
      xPosition: xPosition,
      navigationWidth: navigationWidth,
    );

    if (_lastDragIndex == index) {
      return;
    }

    _lastDragIndex = index;
    HapticFeedback.selectionClick();
    widget.onChanged(index);
  }

  int _nearestTabIndex({
    required double xPosition,
    required double navigationWidth,
  }) {
    final double sideWidth = (navigationWidth - _centerGap) / 2;
    final double itemWidth = sideWidth / 2;
    final List<double> centers = <double>[
      itemWidth * 0.5,
      itemWidth * 1.5,
      sideWidth + _centerGap + (itemWidth * 0.5),
      sideWidth + _centerGap + (itemWidth * 1.5),
    ];

    int nearestIndex = 0;
    double nearestDistance = (xPosition - centers.first).abs();

    for (int index = 1; index < centers.length; index++) {
      final double distance = (xPosition - centers[index]).abs();

      if (distance < nearestDistance) {
        nearestIndex = index;
        nearestDistance = distance;
      }
    }

    return nearestIndex.clamp(0, _itemCount - 1);
  }

  void _selectFromAccessibility(int index) {
    if (index < 0 || index >= _itemCount || index == widget.selectedIndex) {
      return;
    }

    HapticFeedback.selectionClick();
    widget.onChanged(index);
  }
}

class _NotchedBarClipper extends CustomClipper<Path> {
  const _NotchedBarClipper();

  @override
  Path getClip(Size size) {
    return _buildNotchedBarPath(size);
  }

  @override
  bool shouldReclip(covariant _NotchedBarClipper oldClipper) {
    return false;
  }
}

class _NotchedBarBorderPainter extends CustomPainter {
  final Color color;

  const _NotchedBarBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(_buildNotchedBarPath(size), paint);
  }

  @override
  bool shouldRepaint(covariant _NotchedBarBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

Path _buildNotchedBarPath(Size size) {
  const double cornerRadius = 24;
  const double notchHalfWidth = 54;
  const double notchDepth = 30;
  final double centerX = size.width / 2;
  final Path path = Path()
    ..moveTo(cornerRadius, 0)
    ..lineTo(centerX - notchHalfWidth, 0)
    ..cubicTo(centerX - 44, 0, centerX - 42, 9, centerX - 37, 16)
    ..cubicTo(centerX - 29, 26, centerX - 17, notchDepth, centerX, notchDepth)
    ..cubicTo(centerX + 17, notchDepth, centerX + 29, 26, centerX + 37, 16)
    ..cubicTo(centerX + 42, 9, centerX + 44, 0, centerX + notchHalfWidth, 0)
    ..lineTo(size.width - cornerRadius, 0)
    ..quadraticBezierTo(size.width, 0, size.width, cornerRadius)
    ..lineTo(size.width, size.height - cornerRadius)
    ..quadraticBezierTo(
      size.width,
      size.height,
      size.width - cornerRadius,
      size.height,
    )
    ..lineTo(cornerRadius, size.height)
    ..quadraticBezierTo(0, size.height, 0, size.height - cornerRadius)
    ..lineTo(0, cornerRadius)
    ..quadraticBezierTo(0, 0, cornerRadius, 0)
    ..close();

  return path;
}
