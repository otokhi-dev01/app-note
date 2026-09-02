import 'package:flutter/material.dart';

import 'package:Note/core/theme/app_theme.dart';

enum NoteMediaCursorSide { before, after }

/// Transparent left/right hit targets with an iOS-style attachment caret.
class NoteMediaCursorEdges extends StatelessWidget {
  final String keyPrefix;
  final NoteMediaCursorSide? focusedSide;
  final String beforeSemanticLabel;
  final String afterSemanticLabel;
  final VoidCallback onFocusBefore;
  final VoidCallback onFocusAfter;

  const NoteMediaCursorEdges({
    super.key,
    required this.keyPrefix,
    required this.focusedSide,
    required this.beforeSemanticLabel,
    required this.afterSemanticLabel,
    required this.onFocusBefore,
    required this.onFocusAfter,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _MediaCursorEdge(
          keyPrefix: keyPrefix,
          side: NoteMediaCursorSide.before,
          semanticLabel: beforeSemanticLabel,
          isFocused: focusedSide == NoteMediaCursorSide.before,
          onTap: onFocusBefore,
        ),
        _MediaCursorEdge(
          keyPrefix: keyPrefix,
          side: NoteMediaCursorSide.after,
          semanticLabel: afterSemanticLabel,
          isFocused: focusedSide == NoteMediaCursorSide.after,
          onTap: onFocusAfter,
        ),
      ],
    );
  }
}

class _MediaCursorEdge extends StatelessWidget {
  final String keyPrefix;
  final NoteMediaCursorSide side;
  final String semanticLabel;
  final bool isFocused;
  final VoidCallback onTap;

  const _MediaCursorEdge({
    required this.keyPrefix,
    required this.side,
    required this.semanticLabel,
    required this.isFocused,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isBefore = side == NoteMediaCursorSide.before;
    final alignment = isBefore ? Alignment.centerLeft : Alignment.centerRight;
    final position = isBefore ? 'before' : 'after';

    return Align(
      alignment: alignment,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: GestureDetector(
          key: ValueKey('$keyPrefix-focus-$position'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 32,
            height: double.infinity,
            child: Align(
              alignment: alignment,
              child: AnimatedContainer(
                key: isFocused
                    ? ValueKey('$keyPrefix-border-cursor-$position')
                    : null,
                duration: const Duration(milliseconds: 120),
                width: isFocused ? 3 : 0,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.folderYellow,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
