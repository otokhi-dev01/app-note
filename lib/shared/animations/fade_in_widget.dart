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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      builder: (_, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }
}
