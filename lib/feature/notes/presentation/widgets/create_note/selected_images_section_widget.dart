part of '../../view/create_note_view.dart';

class _SelectedImagesSection extends GetView<CreateNoteController> {
  final ValueChanged<NoteDraftImage> onPreview;

  const _SelectedImagesSection({required this.onPreview});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<NoteDraftImage> images = List<NoteDraftImage>.unmodifiable(
        controller.selectedImages.toList(),
      );

      if (images.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: AppGlassSurface(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              _SectionHeader(
                icon: CupertinoIcons.photo_fill,
                title: 'Photos',
                subtitle:
                    '${images.length} ${images.length == 1 ? 'photo' : 'photos'} selected',
              ),

              const SizedBox(height: 14),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: images.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 9,
                  mainAxisSpacing: 9,
                  childAspectRatio: 1.12,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final NoteDraftImage image = images[index];

                  return _SelectedImageTile(
                    key: ValueKey<String>(image.file.path),
                    image: image,
                    enabled: !controller.isSaving.value,
                    onPreview: () {
                      onPreview(image);
                    },
                    onRemove: () {
                      controller.removeImage(image);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }
}
