part of '../editor_view.dart';

class _ModernBottomBar extends StatelessWidget {
  final VoidCallback onChecklist;
  final VoidCallback onAttachment;
  final VoidCallback onSketch;
  final VoidCallback onCompose;
  const _ModernBottomBar({
    required this.onChecklist,
    required this.onAttachment,
    required this.onSketch,
    required this.onCompose,
  });
  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);

    return Container(
      decoration: BoxDecoration(
        color: style.surface,
        border: Border(top: BorderSide(color: style.border, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Checklist',
                icon: Icon(
                  CupertinoIcons.list_bullet_indent,
                  color: style.theme.colorScheme.primary,
                ),
                onPressed: onChecklist,
              ),
              IconButton(
                tooltip: 'Add attachment',
                icon: Icon(
                  CupertinoIcons.camera,
                  color: style.theme.colorScheme.primary,
                ),
                onPressed: onAttachment,
              ),
              IconButton(
                tooltip: 'Drawing',
                icon: Icon(
                  CupertinoIcons.pencil_outline,
                  color: style.theme.colorScheme.primary,
                ),
                onPressed: onSketch,
              ),
              IconButton(
                tooltip: 'Write',
                icon: Icon(
                  CupertinoIcons.square_pencil,
                  color: style.theme.colorScheme.primary,
                ),
                onPressed: onCompose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
