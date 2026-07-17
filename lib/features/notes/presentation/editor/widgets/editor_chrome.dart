part of '../editor_view.dart';

class _CircleButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _CircleButton({super.key, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        icon: child,
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final List<Widget> children;

  const _PillButton({required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
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
      child: Icon(icon, color: style.theme.colorScheme.primary, size: 21),
    );
  }
}
