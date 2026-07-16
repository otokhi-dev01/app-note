import 'package:get/get.dart';
import 'package:notes/features/notes/domain/repositories/attachment_file_repository.dart';
import 'package:notes/features/notes/presentation/attachments/controllers/drawing_editor_controller.dart';

class SketchController extends DrawingEditorController {
  SketchController({AttachmentFileRepository? attachmentFiles})
    : _attachmentFiles = attachmentFiles;

  final AttachmentFileRepository? _attachmentFiles;

  Future<void> saveSketch() async {
    if (points.isEmpty) {
      Get.back();
      return;
    }

    final imageBytes = await screenshotController.capture();
    if (imageBytes != null) {
      final repository =
          _attachmentFiles ?? Get.find<AttachmentFileRepository>();
      final filePath = await repository.saveSketch(imageBytes);
      Get.back(result: filePath);
    }
  }
}
