part of 'folder_list_view.dart';

class _FolderLoadingState extends StatelessWidget {
  const _FolderLoadingState();

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
