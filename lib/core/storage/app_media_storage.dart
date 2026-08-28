import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Copies picker/cache files into app-owned storage that survives hot restart.
class AppMediaStorage {
  AppMediaStorage._();

  static Future<String> persist({
    required String sourcePath,
    required String folder,
    required String fileName,
    bool forceCopy = false,
  }) async {
    final source = File(sourcePath);
    if (!source.existsSync()) {
      throw FileSystemException(
        'Selected media file no longer exists.',
        sourcePath,
      );
    }

    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/$folder');
    if (!directory.existsSync()) await directory.create(recursive: true);

    final directoryPrefix = '${directory.path}${Platform.pathSeparator}';
    if (!forceCopy && source.absolute.path.startsWith(directoryPrefix)) {
      return source.path;
    }

    final extension = _extensionOf(sourcePath);
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final destination = File('${directory.path}/$safeName$extension');
    await destination.writeAsBytes(await source.readAsBytes(), flush: true);
    return destination.path;
  }

  static Future<void> deleteIfManaged({
    required String? path,
    required String folder,
  }) async {
    if (path == null || path.isEmpty) return;

    final documents = await getApplicationDocumentsDirectory();
    final directoryPrefix =
        '${documents.path}/$folder${Platform.pathSeparator}';
    final file = File(path);
    if (file.absolute.path.startsWith(directoryPrefix) && file.existsSync()) {
      await file.delete();
    }
  }

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    final slash = path.lastIndexOf(Platform.pathSeparator);
    return dot > slash ? path.substring(dot).toLowerCase() : '';
  }
}
