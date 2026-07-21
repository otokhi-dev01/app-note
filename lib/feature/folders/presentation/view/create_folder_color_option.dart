part of 'create_folder_view.dart';

class _ColorOption extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 3.5,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 12,
              spreadRadius: selected ? 2 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: selected
            ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
            : null,
      ),
    );
  }
}
