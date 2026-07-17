import 'package:flutter/material.dart';

class FadeInWidget extends StatelessWidget {
  const FadeInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 250),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reducedMotion ? Duration.zero : duration,
      builder: (_, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }
}
