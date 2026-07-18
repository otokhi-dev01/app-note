part of '../editor_view.dart';

class _CircleButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _CircleButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        icon: child,
      ),
    );
  }
}

/// Top app bar for the editor with a close (discard) button on the left and
/// a save action on the right.
class _EditorTopBar extends StatelessWidget {
  const _EditorTopBar({
    required this.onClose,
    required this.onSave,
    required this.isSaving,
  });

  final VoidCallback onClose;
  final VoidCallback onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);
    final scheme = style.theme.colorScheme;

    return SafeArea(
      bottom: false,
      minimum: const EdgeInsets.fromLTRB(8, 4, 12, 4),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            _CircleButton(
              onTap: onClose,
              child: Icon(
                CupertinoIcons.xmark,
                color: scheme.onSurface,
                size: 22,
              ),
            ),
            const Spacer(),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onPressed: isSaving ? null : onSave,
              minimumSize: Size.zero,
              child: isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: scheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Save',
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
