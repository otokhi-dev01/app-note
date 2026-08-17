import 'package:flutter/material.dart';

import 'package:Note/core/theme/app_colors.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/core/utils/date_formatter.dart';
import 'package:Note/core/utils/note_snippet.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/selection_indicator.dart';

/// The row a note is shown as in the notes list, archive, and trash.
///
/// Previously three widgets that were ~85% identical and had drifted apart in
/// their date format and empty-state wording. The differences that actually
/// matter are now parameters.
class AppNoteTile extends StatelessWidget {
  final Note note;

  /// Edit mode: swaps the leading slot for a selection circle.
  final bool isEditing;
  final bool isSelected;

  /// Shows the note's image attachment at the trailing edge when it has one.
  final bool showAttachmentThumbnail;

  /// Trailing chevron, hidden while selecting.
  final bool showChevron;

  /// Overrides the subtitle's leading timestamp (trash shows deletion date).
  final DateTime? timestamp;

  /// Replaces the computed subtitle entirely.
  final String? subtitleOverride;

  final EdgeInsetsGeometry contentPadding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AppNoteTile({
    super.key,
    required this.note,
    this.isEditing = false,
    this.isSelected = false,
    this.showAttachmentThumbnail = false,
    this.showChevron = true,
    this.timestamp,
    this.subtitleOverride,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 4,
    ),
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    final attachment = showAttachmentThumbnail
        ? note.content.whereType<AttachmentBlock>().firstOrNull
        : null;

    return CustomGlassListTile(
      contentPadding: contentPadding,
      onTap: onTap,
      onLongPress: isEditing ? null : onLongPress,
      leading: _buildLeading(),
      title: Text(
        note.displayTitle,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 17,
          letterSpacing: -0.4,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          _subtitle(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.secondaryText,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: _buildTrailing(context, attachment, colors),
    );
  }

  Widget? _buildLeading() {
    if (isEditing) return SelectionIndicator(isSelected: isSelected);
    if (note.isPinned) {
      return const Icon(Icons.push_pin, color: AppTheme.folderPink, size: 16);
    }
    return null;
  }

  Widget? _buildTrailing(
    BuildContext context,
    AttachmentBlock? attachment,
    AppColors colors,
  ) {
    if (attachment != null) return _AttachmentThumbnail(attachment: attachment);
    if (isEditing || !showChevron) return null;
    return Icon(Icons.chevron_right, color: colors.mutedIcon, size: 20);
  }

  String _subtitle() {
    if (subtitleOverride != null) return subtitleOverride!;
    final when = DateFormatter.relative(timestamp ?? note.updatedAt);
    final snippet = NoteSnippet.of(note);
    return when.isEmpty ? snippet : '$when  $snippet';
  }
}

class _AttachmentThumbnail extends StatelessWidget {
  final AttachmentBlock attachment;

  const _AttachmentThumbnail({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: attachment.url != null
              ? NetworkImage(attachment.url!)
              : const AssetImage('assets/images/placeholder.png')
                    as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
