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

    final resolved = await resolve(path);
    if (resolved == null) return;

    final documents = await getApplicationDocumentsDirectory();
    final directoryPrefix =
        '${documents.path}/$folder${Platform.pathSeparator}';
    final file = File(resolved);
    if (file.absolute.path.startsWith(directoryPrefix) && file.existsSync()) {
      await file.delete();
    }
  }

  /// Resolves [path] into an absolute path.
  ///
  /// If [path] is already absolute, it's returned as-is. If it's a relative
  /// path (no leading `/`), it's resolved against the application documents
  /// directory — which survives app container UUID changes on iOS.
  static Future<String?> resolve(String? path) async {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('/') || path.contains(':\\')) return path;

    final documents = await getApplicationDocumentsDirectory();
    return '${documents.path}/$path';
  }

  /// Extracts the relative part of [absolutePath] if it lives inside the
  /// application documents directory.
  static Future<String> makeRelative(String absolutePath) async {
    final documents = await getApplicationDocumentsDirectory();
    final prefix = '${documents.path}/';
    if (absolutePath.startsWith(prefix)) {
      return absolutePath.substring(prefix.length);
    }
    return absolutePath;
  }

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    final slash = path.lastIndexOf(Platform.pathSeparator);
    return dot > slash ? path.substring(dot).toLowerCase() : '';
  }
}
