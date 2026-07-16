part of '../editor_view.dart';

class _CircleButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Color? backgroundColor;

  const _CircleButton({
    required this.onTap,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: backgroundColor ?? style.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: style.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final List<Widget> children;

  const _PillButton({required this.children});

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: style.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: style.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      onPressed: onTap,
      minimumSize: Size.zero,
      child: Icon(icon, color: style.secondaryText, size: 22),
    );
  }
}
