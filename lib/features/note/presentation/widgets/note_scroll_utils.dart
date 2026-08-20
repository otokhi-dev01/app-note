import 'package:flutter/widgets.dart';

/// Scrolls the focused block into view above the keyboard. Called from a
/// block's own `Focus.onFocusChange` (text blocks, checklist items) so that
/// pressing Return to create a new line/item — or the note's initial
/// autofocus — never leaves the cursor hidden behind the keyboard, the way
/// Flutter's default focus handling doesn't quite manage inside a
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
