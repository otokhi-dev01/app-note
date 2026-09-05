import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';

/// Shared folder path shown in folder details and the note editor.
class FolderBreadcrumb extends StatelessWidget {
  final Folder? folder;
  final List<Folder> folderPath;
  final String fallbackFolderLabel;
  final String? noteTitle;
  final String semanticLabel;
  final bool showDisclosure;
  final Key? pathKey;

  const FolderBreadcrumb({
    super.key,
    this.folder,
    required this.folderPath,
    required this.fallbackFolderLabel,
    this.noteTitle,
    required this.semanticLabel,
    this.showDisclosure = false,
    this.pathKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final folderColor = folder?.color ?? scheme.primary;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: folderColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: folderColor.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (folderPath.isEmpty) ...[
                    _folderIcon(folder, folderColor),
                    TextSpan(text: ' $fallbackFolderLabel'),
                  ] else
                    for (var index = 0; index < folderPath.length; index++) ...[
                      if (index > 0) const TextSpan(text: ' › '),
                      _folderIcon(folderPath[index], folderPath[index].color),
                      TextSpan(text: ' ${folderPath[index].displayName}'),
                    ],
                  if (noteTitle != null) TextSpan(text: ' › $noteTitle'),
                ],
              ),
              key: pathKey,
              semanticsLabel: semanticLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (showDisclosure) ...[
            const SizedBox(width: 5),
            Icon(
              CupertinoIcons.chevron_down,
              size: 11,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
            ),
          ],
        ],
      ),
    );
  }

  WidgetSpan _folderIcon(Folder? folder, Color color) => WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: ExcludeSemantics(
      child: folder != null
          ? FolderGlyph(folder: folder, size: 14)
          : Icon(
              FolderAppearance.iconFor(FolderAppearance.defaultIconName),
              size: 14,
              color: color,
            ),
    ),
  );
}
