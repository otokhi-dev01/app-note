part of 'main_tab_header_widget.dart';

class MainTabHeaderAction extends StatelessWidget {
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
    final Widget button = _LiquidHeaderButton(
      icon: icon,
      onPressed: onPressed,
      highlighted: highlighted,
      destructive: destructive,
      badgeCount: badgeCount,
      compact: compact,
    );

    if (tooltip == null || tooltip!.trim().isEmpty) {
      return button;
    }

    return Tooltip(message: tooltip!, child: button);
  }
}
