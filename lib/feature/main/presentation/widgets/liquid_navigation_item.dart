part of 'liquid_bottom_navigation_widget.dart';

class _NavigationItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.index,
    required this.selectedIndex,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: Curves.fastOutSlowIn,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 14 : 0,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? colors.primary.withValues(alpha: 0.14) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? colors.primary : colors.onSurfaceVariant.withValues(alpha: 0.65),
                size: 24,
              ),
              Flexible(
                child: ClipRect(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    child: isSelected 
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                letterSpacing: -0.2,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
