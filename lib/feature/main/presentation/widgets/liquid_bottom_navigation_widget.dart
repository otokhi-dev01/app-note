import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

part 'liquid_navigation_create_note_button.dart';
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

  static const int _pageCount = 4;

  @override
  Widget build(BuildContext context) {
    final double safePage = page.isFinite
        ? page.clamp(0.0, (_pageCount - 1).toDouble())
        : selectedIndex.clamp(0, _pageCount - 1).toDouble();

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        height: 84,
        child: _NotchedNavigationBar(
          page: safePage,
          selectedIndex: selectedIndex,
          onChanged: onChanged,
          onCreateNote: onCreateNote,
        ),
      ),
    );
  }
}
