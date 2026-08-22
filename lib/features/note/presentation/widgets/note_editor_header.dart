import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';

/// The centered timestamp above a note's title, with the folder it lives in
/// directly underneath.
///
/// Shared by both editor screens — [CreateNoteView] and [NoteContentEditor] —
/// so a new note and an existing one open with the same header instead of two
/// separately-drifting copies of it. The folder resolution itself
/// ([NoteDetailController.resolveFolder] / `resolveFolderLabel`) lives on the
/// controller rather than here, so [NoteDetailController.exportNoteToPdf]
/// reads the exact same folder line this header shows on-screen.
class NoteEditorHeader extends StatelessWidget {
  final NoteDetailController controller;

  const NoteEditorHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    // Its own Obx rather than relying on the callers': both build this from
    // inside an outer Obx, but that only tracks reads made in the builder
    // closure itself — this widget's build() runs later, outside it, so the
    // timestamp and the folder would stop updating without this. Same
    // reasoning as the Obx in NoteBlockList.
    return Obx(() {
      final note = controller.currentNote.value;
      final date = note?.updatedAt ?? DateTime.now();
      final folder = controller.resolveFolder(note?.folderId ?? 0);
      final folderName = controller.resolveFolderLabel();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [if (folderName.isNotEmpty) ...[
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // A folder carrying a real icon draws it in its own color;
                // anything else (no folder record on this device, an
                // unresolved id) falls back to a plain muted folder glyph so
                // the row still reads as "this note lives here".
                if (folder != null)
                  FolderGlyph(folder: folder, size: 14)
                else
                  Icon(
                    FolderAppearance.iconFor(FolderAppearance.defaultIconName),
                    size: 14,
                    color: muted,
                  ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    folderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Autosave progress rides along here instead of getting a
                // blocking spinner over the whole screen.
                if (controller.isSaving.value)
                  Text(
                    'note_editor_saving_indicator'.tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: muted,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            DateFormat("MMMM d, yyyy 'at' h:mm a").format(date),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: muted,
              fontSize: 13,
            ),
          ),
        ],
      );
    });
  }
}
