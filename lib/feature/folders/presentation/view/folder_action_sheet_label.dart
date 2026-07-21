part of 'folder_list_view.dart';

class _ActionSheetLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionSheetLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 20),
        const SizedBox(width: 9),
        Text(label),
      ],
    );
  }
}
