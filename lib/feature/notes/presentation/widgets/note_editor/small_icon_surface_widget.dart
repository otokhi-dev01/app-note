part of '../../view/note_editor_view.dart';

class _SmallIconSurface extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SmallIconSurface({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: color),
    );
  }
}
