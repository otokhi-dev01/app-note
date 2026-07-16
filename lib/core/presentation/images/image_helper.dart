import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageHelper {
  /// Resolves an absolute path that might be broken due to iOS/Android container ID changes.
  /// It extracts the filename and joins it with the current Documents directory.
  static Future<String> resolvePath(String path) async {
    if (path.isEmpty) return path;
    if (_networkUrl(path) != null) return path;
    final file = File(path);
    if (await file.exists()) return path;
    // If file doesn't exist, it might be due to a path change in iOS Simulator/Device
    try {
      final fileName = p.basename(path);
      final directory = await getApplicationDocumentsDirectory();
      final newPath = p.join(directory.path, fileName);
      if (await File(newPath).exists()) {
        return newPath;
      }
    } catch (_) {}
    return path;
  }

  static Widget buildSafeImage(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    double radius = 8,
  }) {
    final networkUrl = _networkUrl(path);
    if (networkUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          networkUrl,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : _placeholder(width: width, height: height),
          errorBuilder: (context, error, stackTrace) =>
              _placeholder(width: width, height: height, showIcon: true),
        ),
      );
    }

    return FutureBuilder<String>(
      future: resolvePath(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _placeholder(width: width, height: height);
        }

        final resolvedPath = snapshot.data ?? path;

        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.file(
            File(resolvedPath),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) =>
                _placeholder(width: width, height: height, showIcon: true),
          ),
        );
      },
    );
  }

  static String? _networkUrl(String path) {
    final trimmedPath = path.trim();
    if (trimmedPath.isEmpty) return null;

    final uri = Uri.tryParse(trimmedPath);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return uri.toString();
    }
    return null;
  }

  static Widget _placeholder({
    double? width,
    double? height,
    bool showIcon = false,
  }) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: showIcon
          ? Icon(
              CupertinoIcons.photo,
              color: Colors.grey.withValues(alpha: 0.4),
              size: width == null
                  ? 28
                  : (width / 2).clamp(20.0, 56.0).toDouble(),
            )
          : null,
    );
  }
}
