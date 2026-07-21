part of 'liquid_note_card_widget.dart';

class _NoteMenuButton extends StatelessWidget {
  final NoteEntity note;
  final VoidCallback onTogglePin;
  final VoidCallback onArchive;
  final VoidCallback onLock;

  const _NoteMenuButton({
    required this.note,
    required this.onTogglePin,
    required this.onArchive,
    required this.onLock,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        showCupertinoModalPopup<void>(
          context: context,
          builder: (BuildContext sheetContext) {
            return CupertinoActionSheet(
              title: Text(
                note.title.trim().isEmpty ? 'Untitled Note' : note.title,
              ),
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    onTogglePin();
                  },
                  child: Text(note.isPinned ? 'Unpin Note' : 'Pin Note'),
                ),
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    onArchive();
                  },
                  child: Text(
                    note.isArchived ? 'Remove from Archive' : 'Archive Note',
                  ),
                ),
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    onLock();
                  },
                  child: Text(note.isLocked ? 'Unlock Note' : 'Lock Note'),
                ),
              ],
              cancelButton: CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                },
                child: const Text('Cancel'),
              ),
            );
          },
        );
      },
      child: Icon(
        Icons.more_horiz_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
