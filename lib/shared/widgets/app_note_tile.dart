import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/core/storage/settings_preferences.dart';
import 'package:Note/core/theme/app_colors.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/core/utils/attachment_url.dart';
import 'package:Note/core/utils/date_formatter.dart';
import 'package:Note/core/utils/note_snippet.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/selection_indicator.dart';

class AppNoteTile extends StatelessWidget {
  final Note note;

  final bool isEditing;
  final bool isSelected;
  final bool showAttachmentThumbnail;
  final bool showChevron;
  final DateTime? timestamp;
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
    if (!Get.isRegistered<SettingsPreferences>()) {
      return _buildTile(context, hidePreview: false);
    }

    final preferences = Get.find<SettingsPreferences>();
    return Obx(
      () =>
          _buildTile(context, hidePreview: preferences.hideNotePreviews.value),
    );
  }

  Widget _buildTile(BuildContext context, {required bool hidePreview}) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    final attachment = showAttachmentThumbnail && !hidePreview
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
          _subtitle(hidePreview: hidePreview),
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

  String _subtitle({required bool hidePreview}) {
    if (subtitleOverride != null) return subtitleOverride!;
    final when = DateFormatter.relative(timestamp ?? note.updatedAt);
    if (hidePreview) return when;
    final snippet = NoteSnippet.of(note);
    return when.isEmpty ? snippet : '$when  $snippet';
  }
}

class _AttachmentThumbnail extends StatelessWidget {
  final AttachmentBlock attachment;

  const _AttachmentThumbnail({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final localPath = normalizeLocalPath(attachment.localPath);
    if (localPath != null && File(localPath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(localPath),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(context),
        ),
      );
    }

    final networkUrl = normalizeAttachmentUrl(attachment.url);
    if (networkUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          networkUrl,
          headers: attachmentAuthHeaders(),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(context),
        ),
      );
    }

    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        CupertinoIcons.photo,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
