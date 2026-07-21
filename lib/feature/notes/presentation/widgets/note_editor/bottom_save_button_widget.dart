part of '../../view/note_editor_view.dart';

class _BottomSaveButton extends StatelessWidget {
  final bool saving;
  final bool enabled;
  final VoidCallback onPressed;

  const _BottomSaveButton({
    required this.saving,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: saving
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(colors.onPrimary),
              ),
            )
          : const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(CupertinoIcons.checkmark_alt, size: 19),
                SizedBox(width: 8),
                Text(
                  'Save Changes',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
    );
  }
}
