import 'package:flutter/material.dart';

/// The filled/hollow circle shown at the leading edge of a tile in edit mode.
///
/// Was duplicated byte-for-byte as `_buildSelectionIndicator` in both
/// `NoteListTile` and `ArchiveNoteTile`.
class SelectionIndicator extends StatelessWidget {
  final bool isSelected;
  final double size;

  const SelectionIndicator({
    super.key,
    required this.isSelected,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? scheme.onSurface : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? scheme.onSurface
              : scheme.onSurfaceVariant.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: isSelected
          ? Icon(Icons.check, color: scheme.surface, size: size * 0.64)
          : null,
    );
  }
}
