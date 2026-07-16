import 'dart:io';
import 'dart:typed_data';

import 'package:notes/features/notes/domain/repositories/attachment_file_repository.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

final class LocalAttachmentFileRepository implements AttachmentFileRepository {
  const LocalAttachmentFileRepository();

  @override
  Future<String> importImage(String sourcePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final extension = path.extension(sourcePath);
    final fileName =
        'note_image_${DateTime.now().millisecondsSinceEpoch}$extension';
    final destination = path.join(directory.path, fileName);
    await File(sourcePath).copy(destination);
    return destination;
  }

  @override
  Future<String> saveSketch(Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'sketch_${DateTime.now().millisecondsSinceEpoch}.png';
    final destination = path.join(directory.path, fileName);
    await File(destination).writeAsBytes(bytes);
    return destination;
  }

  @override
  Future<String> saveEditedImage(String sourcePath, Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final destination = path.join(
      directory.path,
      'edited_${path.basename(sourcePath)}',
    );
    await File(destination).writeAsBytes(bytes);
    return destination;
  }

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> deleteAll(Iterable<String> paths) async {
    for (final path in paths) {
      try {
        await delete(path);
      } catch (_) {
        // Cleanup is best effort; one missing file must not block the rest.
      }
    }
  }
}
