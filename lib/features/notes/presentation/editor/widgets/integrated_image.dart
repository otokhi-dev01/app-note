part of '../editor_view.dart';

class _IntegratedImage extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  final VoidCallback onEdit;
  final VoidCallback onTap;
  const _IntegratedImage({
    required this.path,
    required this.onRemove,
    required this.onEdit,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final style = HomeStyle.of(context);
    return Container(
      constraints: BoxConstraints(maxWidth: Get.width),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: style.border.withValues(alpha: .68)),
        boxShadow: [
          BoxShadow(
            color: style.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Semantics(
            button: true,
            label: 'Open attached image options',
            child: GestureDetector(
              onTap: onTap,
              child: ImageHelper.buildSafeImage(
                path,
                width: double.infinity,
                height: 248,
                radius: 18,
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: AppGlassSurface(
              borderRadius: BorderRadius.circular(22),
              hasShadow: false,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _InlineImageButton(
                    tooltip: 'Edit image',
                    icon: CupertinoIcons.pencil,
                    onPressed: onEdit,
                  ),
                  Container(width: .5, height: 24, color: style.border),
                  _InlineImageButton(
                    tooltip: 'Remove image',
                    icon: CupertinoIcons.xmark,
                    onPressed: onRemove,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineImageButton extends StatelessWidget {
  const _InlineImageButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
    );
  }
}
