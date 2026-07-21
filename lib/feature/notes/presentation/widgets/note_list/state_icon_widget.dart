part of '../../view/note_list_view.dart';

class _StateIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _StateIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 38, color: color),
    );
  }
}
