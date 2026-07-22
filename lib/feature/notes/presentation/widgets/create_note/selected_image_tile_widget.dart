part of '../../view/create_note_view.dart';

class _SelectedImageTile extends StatelessWidget {
  final NoteDraftImage image;
  final bool enabled;
  final VoidCallback onPreview;
  final VoidCallback onRemove;

  const _SelectedImageTile({
    super.key,
    required this.image,
    required this.enabled,
    required this.onPreview,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Material(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPreview,
              child: Hero(
                tag: image.file.path,
                child: Image.file(
                  File(image.file.path),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return Center(
                          child: Icon(
                            CupertinoIcons.photo_on_rectangle,
                            color: colors.onSurfaceVariant,
                            size: 30,
                          ),
                        );
                      },
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  CupertinoIcons.arrow_up_left_arrow_down_right,
                  color: Colors.white,
                  size: 11,
                ),
                SizedBox(width: 4),
                Text(
                  'View',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            pressedOpacity: 0.55,
            onPressed: enabled ? onRemove : null,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: enabled ? 0.66 : 0.35),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                CupertinoIcons.xmark,
                color: Colors.white,
                size: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
