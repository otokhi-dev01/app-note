part of '../editor_view.dart';

class _ModernBottomBar extends StatelessWidget {
  const _ModernBottomBar({
    required this.onChecklist,
    required this.onAttachment,
    required this.onSketch,
    required this.onCompose,
    required this.onFormat,
    required this.onDone,
    required this.keyboardVisible,
  });

  final VoidCallback onChecklist;
  final VoidCallback onAttachment;
  final VoidCallback onSketch;
  final VoidCallback onCompose;
  final VoidCallback onFormat;
  final VoidCallback onDone;
  final bool keyboardVisible;

  @override
  Widget build(BuildContext context) {
    final scheme = HomeStyle.of(context).theme.colorScheme;
    final iconButtonStyle = IconButton.styleFrom(
      minimumSize: const Size.square(44),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return SafeArea(
      key: const ValueKey('editor_bottom_toolbar'),
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: AppGlassSurface(
        borderRadius: BorderRadius.circular(30),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              if (keyboardVisible)
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size.square(44),
                    onPressed: onFormat,
                    child: Text(
                      'Aa',
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: IconButton(
                  tooltip: 'Checklist',
                  style: iconButtonStyle,
                  icon: Icon(
                    CupertinoIcons.list_bullet_indent,
                    color: scheme.primary,
                  ),
                  onPressed: onChecklist,
                ),
              ),
              Expanded(
                child: IconButton(
                  tooltip: 'Add attachment',
                  style: iconButtonStyle.copyWith(
                    backgroundColor: WidgetStatePropertyAll(
                      scheme.primary.withValues(alpha: .14),
                    ),
                  ),
                  icon: Icon(
                    CupertinoIcons.photo_on_rectangle,
                    color: scheme.primary,
                  ),
                  onPressed: onAttachment,
                ),
              ),
              Expanded(
                child: IconButton(
                  tooltip: 'Drawing',
                  style: iconButtonStyle,
                  icon: Icon(
                    CupertinoIcons.pencil_outline,
                    color: scheme.primary,
                  ),
                  onPressed: onSketch,
                ),
              ),
              Expanded(
                child: keyboardVisible
                    ? CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size.square(44),
                        onPressed: onDone,
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : IconButton(
                        tooltip: 'Write',
                        style: iconButtonStyle.copyWith(
                          backgroundColor: WidgetStatePropertyAll(
                            scheme.primary,
                          ),
                        ),
                        icon: Icon(
                          CupertinoIcons.text_cursor,
                          color: scheme.onPrimary,
                        ),
                        onPressed: onCompose,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
