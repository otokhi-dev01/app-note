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
        color: style.background,
        border: Border(top: BorderSide(color: style.border, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  CupertinoIcons.list_bullet_indent,
                  color: AppColors.magenta,
                ),
                onPressed: onChecklist,
              ),
              IconButton(
                icon: const Icon(
                  CupertinoIcons.camera,
                  color: AppColors.magenta,
                ),
                onPressed: onAttachment,
              ),
              IconButton(
                icon: const Icon(
                  CupertinoIcons.pencil_outline,
                  color: AppColors.magenta,
                ),
                onPressed: onSketch,
              ),
              IconButton(
                icon: const Icon(
                  CupertinoIcons.square_pencil,
                  color: AppColors.magenta,
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
