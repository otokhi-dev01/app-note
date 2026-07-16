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

    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Material(
        color: backgroundColor ?? style.secondarySurface,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(dimension: 40, child: Center(child: child)),
        ),
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
        color: style.secondarySurface,
        borderRadius: BorderRadius.circular(20),
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
      child: Icon(icon, color: style.theme.colorScheme.primary, size: 21),
    );
  }
}
