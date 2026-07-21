part of '../../view/note_list_view.dart';

class _CreateNoteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CreateNoteButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;

    return Semantics(
      button: true,
      label: 'Create note',
      child: SizedBox(
        width: 38,
        height: 38,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          pressedOpacity: 0.45,
          onPressed: onPressed,
          child: Icon(CupertinoIcons.square_pencil, size: 23, color: primary),
        ),
      ),
    );
  }
}
