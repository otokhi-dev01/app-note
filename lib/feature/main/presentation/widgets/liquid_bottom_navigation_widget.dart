import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controller/main_navigation_controller.dart';

part 'liquid_navigation_item.dart';
part 'notched_navigation_bar.dart';

class LiquidBottomNavigation extends StatelessWidget {
  /// Continuous PageView position, from folders at `0.0` through profile at
  /// `3.0`.
  final double page;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onCreateNote;

  const LiquidBottomNavigation({
    super.key,
    required this.page,
    required this.selectedIndex,
    required this.onChanged,
    required this.onCreateNote,
  });

  @override
  Widget build(BuildContext context) {
    final double safePage = page.isFinite
        ? page.clamp(0.0, (MainNavigationController.screenCount - 1).toDouble())
        : 0.0;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: _PillNavigationBar(
        page: safePage,
        selectedIndex: selectedIndex,
        onChanged: onChanged,
        onCreateNote: onCreateNote,
      ),
    );
  }
}
