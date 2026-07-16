import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:notes/features/notes/domain/entities/folder.dart';
import 'package:notes/features/notes/domain/entities/note.dart';
import 'package:notes/features/notes/domain/repositories/note_repository.dart';
import 'package:notes/features/notes/domain/usecases/create_folder_usecase.dart';
import 'package:notes/features/notes/domain/usecases/get_folders_usecase.dart';

import '../home_style.dart';

part 'move_note_sheet.dart';
part 'recently_deleted_sheet.dart';
part 'share_bottom_sheet.dart';

class _NotesSheet extends StatelessWidget {
  const _NotesSheet({required this.child, required this.maxHeightFactor});

  final Widget child;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
      ),
      color: scheme.surface,
      child: SafeArea(top: false, child: child),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: scheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class _SheetIconButton extends StatelessWidget {
  const _SheetIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isDestructive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isDestructive ? scheme.error : scheme.primary;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      style: IconButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.12),
        shape: const CircleBorder(),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class _SheetSectionLabel extends StatelessWidget {
  const _SheetSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
