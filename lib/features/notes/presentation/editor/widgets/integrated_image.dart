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
    return Container(
      constraints: BoxConstraints(maxWidth: Get.width * 0.8),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ImageHelper.buildSafeImage(
            path,
            width: double.infinity,
            radius: 12,
          ),
        ),
      ),
    );
  }
}
