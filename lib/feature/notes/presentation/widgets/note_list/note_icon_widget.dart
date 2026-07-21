part of '../../view/note_list_view.dart';

class _NoteIcon extends StatelessWidget {
  final Color color;
  final bool locked;

  const _NoteIcon({required this.color, required this.locked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Icon(
        locked ? CupertinoIcons.lock_fill : CupertinoIcons.doc_text_fill,
        size: 21,
        color: color,
      ),
    );
  }
}
