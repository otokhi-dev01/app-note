part of '../../view/create_note_view.dart';

class _PreviewCloseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _PreviewCloseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      pressedOpacity: 0.55,
      onPressed: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(CupertinoIcons.xmark_circle,
            size: 20, color: Colors.white,
            fontWeight: FontWeight.bold,),
      ),
    );
  }
}
