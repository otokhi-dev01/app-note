import 'package:get/get.dart';
import 'package:notes/features/notes/domain/repositories/attachment_file_repository.dart';
import 'package:notes/features/notes/presentation/attachments/controllers/drawing_editor_controller.dart';

class ImageEditorController extends DrawingEditorController {
  ImageEditorController(
    this.imagePath, {
    AttachmentFileRepository? attachmentFiles,
  }) : _attachmentFiles = attachmentFiles;

  final String imagePath;
  final AttachmentFileRepository? _attachmentFiles;

  Future<void> saveImage() async {
    final imageBytes = await screenshotController.capture();
    if (imageBytes != null) {
      final repository =
          _attachmentFiles ?? Get.find<AttachmentFileRepository>();
      final filePath = await repository.saveEditedImage(imagePath, imageBytes);
      Get.back(result: filePath);
    }
  }
}
