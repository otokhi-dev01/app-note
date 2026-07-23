part of 'liquid_bottom_navigation_widget.dart';

class _PillNavigationBar extends StatelessWidget {
  final double page;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onCreateNote;

  const _PillNavigationBar({
    required this.page,
    required this.selectedIndex,
    required this.onChanged,
    required this.onCreateNote,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: isDark ? 0.72 : 0.85),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.18 : 0.10),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.shadow.withValues(alpha: isDark ? 0.30 : 0.14),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _buildItem(
                index: 0,
                label: 'notes'.tr,
                icon: CupertinoIcons.doc_text,
                selectedIcon: CupertinoIcons.doc_text_fill,
                colors: colors,
              ),
              _buildItem(
                index: 1,
                label: 'folders'.tr,
                icon: CupertinoIcons.folder,
                selectedIcon: CupertinoIcons.folder_fill,
                colors: colors,
              ),
              _buildActionItem(
                icon: CupertinoIcons.add,
                onPressed: onCreateNote,
                colors: colors,
              ),
              _buildItem(
                index: 3,
                label: 'search'.tr,
                icon: CupertinoIcons.search,
                selectedIcon: CupertinoIcons.search,
                colors: colors,
              ),
              _buildItem(
                index: 4,
                label: 'settings'.tr,
                icon: CupertinoIcons.gear,
                selectedIcon: CupertinoIcons.gear_solid,
                colors: colors,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
    required ColorScheme colors,
  }) {
    return Expanded(
      flex: selectedIndex == index ? 6 : 2,
      child: _NavigationItem(
        index: index,
        selectedIndex: selectedIndex,
        label: label,
        icon: icon,
        selectedIcon: selectedIcon,
        onTap: () => onChanged(index),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required VoidCallback onPressed,
    required ColorScheme colors,
  }) {
    return Expanded(
      flex: 2,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
