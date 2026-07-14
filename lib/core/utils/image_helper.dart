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

  static Widget buildSafeImage(String path, {double? width, double? height, BoxFit fit = BoxFit.cover, double radius = 8}) {
    return FutureBuilder<String>(
      future: resolvePath(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey.withValues(alpha: 0.1),
          );
        }

        final resolvedPath = snapshot.data ?? path;
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.file(
            File(resolvedPath),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: width,
                height: height,
                color: Colors.grey.withValues(alpha: 0.1),
                child: Icon(CupertinoIcons.photo, color: Colors.grey.withValues(alpha: 0.4), size: (width ?? 20) / 2),
              );
            },
          ),
        );
      },
    );
  }
}
