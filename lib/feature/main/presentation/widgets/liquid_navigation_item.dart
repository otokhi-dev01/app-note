part of 'liquid_bottom_navigation_widget.dart';

class _NavigationItem extends StatelessWidget {
  final int pageIndex;
  final double page;
  final bool selected;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final VoidCallback onAccessibilityTap;

  const _NavigationItem({
    required this.pageIndex,
    required this.page,
    required this.selected,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onAccessibilityTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double distance = (page - pageIndex).abs();
    final double rawProgress = (1.0 - distance).clamp(0.0, 1.0).toDouble();
    final double progress = Curves.easeOutCubic.transform(rawProgress);
    final Color inactiveColor = colors.onSurfaceVariant.withValues(alpha: 0.78);
    final Color foregroundColor =
        Color.lerp(inactiveColor, colors.primary, progress) ?? inactiveColor;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onAccessibilityTap,
      child: ExcludeSemantics(
        child: Center(
          child: SizedBox(
            width: 54,
            height: 52,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Transform.translate(
                  offset: Offset(0, -1.5 * progress),
                  child: Transform.scale(
                    scale: 0.96 + (progress * 0.08),
                    child: Icon(
                      progress >= 0.5 ? selectedIcon : icon,
                      size: 24,
                      color: foregroundColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  width: 10 + (progress * 10),
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: progress),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
