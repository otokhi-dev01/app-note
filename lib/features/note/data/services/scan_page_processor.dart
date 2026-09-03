import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;
import 'package:path_provider/path_provider.dart';

import 'package:Note/features/note/domain/entities/scanned_document_draft.dart';

class PreparedScanPages {
  final List<String> paths;
  final List<String> generatedPaths;

  const PreparedScanPages({required this.paths, required this.generatedPaths});

  Future<void> cleanUp() async {
    for (final path in generatedPaths) {
      try {
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {
        // These are derived cache files; cleanup is best effort.
      }
    }
  }
}

/// Applies non-destructive review adjustments to scan pages before the final
/// PDF is built. Untouched pages keep their original path and avoid a lossy
/// re-encode.
Future<PreparedScanPages> prepareScannedPages(
  List<ScannedPageDraft> pages,
) async {
  final cache = await getTemporaryDirectory();
  final token = DateTime.now().microsecondsSinceEpoch;
  final paths = <String>[];
  final generated = <String>[];

  try {
    for (var index = 0; index < pages.length; index++) {
      final page = pages[index];
      final normalizedTurns = page.quarterTurns % 4;
      if (normalizedTurns == 0 && page.filter == ScanPageFilter.color) {
        paths.add(page.path);
        continue;
      }

      final outputPath = '${cache.path}/scan_review_${token}_${index + 1}.jpg';
      final renderedPath = await compute(_renderScanPage, <String, Object>{
        'inputPath': page.path,
        'outputPath': outputPath,
        'quarterTurns': normalizedTurns,
        'filter': page.filter.name,
      });
      paths.add(renderedPath);
      generated.add(renderedPath);
    }
    return PreparedScanPages(paths: paths, generatedPaths: generated);
  } catch (_) {
    await PreparedScanPages(paths: paths, generatedPaths: generated).cleanUp();
    rethrow;
  }
}

String _renderScanPage(Map<String, Object> request) {
  final inputPath = request['inputPath']! as String;
  final outputPath = request['outputPath']! as String;
  final quarterTurns = request['quarterTurns']! as int;
  final filter = ScanPageFilter.values.byName(request['filter']! as String);

  final sourceBytes = File(inputPath).readAsBytesSync();
  final decoded = image.decodeImage(sourceBytes);
  if (decoded == null) {
    throw StateError('The scanned page is not a valid image');
  }

  image.Image rendered = image.bakeOrientation(decoded);
  if (quarterTurns != 0) {
    rendered = image.copyRotate(rendered, angle: quarterTurns * 90);
  }
  rendered = switch (filter) {
    ScanPageFilter.color => rendered,
    ScanPageFilter.grayscale => image.grayscale(rendered),
    ScanPageFilter.blackAndWhite => image.luminanceThreshold(
      image.grayscale(rendered),
      threshold: 0.55,
    ),
  };

  File(outputPath).writeAsBytesSync(image.encodeJpg(rendered, quality: 92));
  return outputPath;
}
