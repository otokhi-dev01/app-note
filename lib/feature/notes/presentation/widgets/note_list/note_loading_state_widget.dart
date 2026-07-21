part of '../../view/note_list_view.dart';

class _NoteLoadingState extends StatelessWidget {
  const _NoteLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CupertinoActivityIndicator(
        radius: 15,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
