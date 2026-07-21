part of '../../view/create_note_view.dart';

class _ImagePreviewPage extends StatelessWidget {
  final NoteDraftImage image;

  const _ImagePreviewPage({required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(80),
              child: Center(
                child: Image.file(
                  File(image.file.path),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              CupertinoIcons.photo_on_rectangle,
                              color: Colors.white70,
                              size: 50,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Unable to display image',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        );
                      },
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  _PreviewCloseButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'Pinch to zoom',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
