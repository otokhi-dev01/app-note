import 'package:flutter/material.dart';

class SplashGlowCircle extends StatelessWidget {
  const SplashGlowCircle({required this.size, required this.color, super.key});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
