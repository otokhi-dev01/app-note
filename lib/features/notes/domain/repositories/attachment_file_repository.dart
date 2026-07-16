import 'dart:typed_data';

abstract interface class AttachmentFileRepository {
  Future<String> importImage(String sourcePath);

  Future<String> saveSketch(Uint8List bytes);

  Future<String> saveEditedImage(String sourcePath, Uint8List bytes);

  Future<void> delete(String path);

  Future<void> deleteAll(Iterable<String> paths);
}
