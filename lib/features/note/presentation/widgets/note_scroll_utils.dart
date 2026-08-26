import 'package:flutter/widgets.dart';

/// [CustomScrollView] of mixed block types.
void ensureBlockVisible(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.3,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  });
}
