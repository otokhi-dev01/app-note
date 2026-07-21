part of '../../view/create_note_view.dart';

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: label,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        pressedOpacity: 0.45,
        onPressed: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(
            icon,
            size: highlighted ? 24 : 22,
            color: highlighted ? colors.primary : colors.onSurface,
          ),
        ),
      ),
    );
  }
}
