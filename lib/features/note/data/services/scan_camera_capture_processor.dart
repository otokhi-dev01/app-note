// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:image/image.dart' as image;
// import 'package:path_provider/path_provider.dart';

// import 'package:Note/features/note/presentation/widgets/document_scan_camera_screen.dart'
//     show DocumentScanCameraFilterPreset;

// /// Maps a camera-screen filter preset onto document_scan's own edge-detection
// /// + look filter. Grey/B&W reuse document_scan's grayscale/black-white math
// /// directly; Original/Darken/Lighten all crop uncorrected color (`none`) since
// /// darken/lighten are baked separately via [brightnessForPreset] +
// /// [applyCaptureBrightness] — document_scan has no exposure-style filter.
// ScanFilter scanFilterForPreset(DocumentScanCameraFilterPreset preset) =>
//     switch (preset) {
//       DocumentScanCameraFilterPreset.grey => ScanFilter.grayscale,
//       DocumentScanCameraFilterPreset.blackAndWhite => ScanFilter.blackWhite,
//       _ => ScanFilter.none,
//     };

// /// The [applyCaptureBrightness] scalar for a preset, or `null` when the preset
// /// needs no brightness bake (its look is fully expressed by
// /// [scanFilterForPreset]).
// double? brightnessForPreset(DocumentScanCameraFilterPreset preset) =>
//     switch (preset) {
//       DocumentScanCameraFilterPreset.darken => 0.75,
//       DocumentScanCameraFilterPreset.lighten => 1.3,
//       _ => null,
//     };

// /// Bakes a brightness adjustment into a captured document-scan page.
// ///
// /// `document_scan`'s own `ScanFilter` has no exposure-style adjustment, so the
// /// camera screen's Darken/Lighten presets are applied here as a separate,
// /// pure-Dart step over the already perspective-corrected page. Runs on a
// /// background isolate via [compute], matching the pattern used for the review
// /// page's rotate/filter bake in `scan_page_processor.dart`.
// ///
// /// [brightness] is `image.adjustColor`'s scalar: `1.0` is unmodified, `< 1.0`
// /// darker, `> 1.0` brighter.
// Future<String> applyCaptureBrightness({
//   required String inputPath,
//   required double brightness,
// }) async {
//   final directory = await getTemporaryDirectory();
//   final token = DateTime.now().microsecondsSinceEpoch;
//   final outputPath = '${directory.path}/document_scan_bright_$token.jpg';
//   return compute(_renderBrightnessAdjustedPage, <String, Object>{
//     'inputPath': inputPath,
//     'outputPath': outputPath,
//     'brightness': brightness,
//   });
// }

// String _renderBrightnessAdjustedPage(Map<String, Object> request) {
//   final inputPath = request['inputPath']! as String;
//   final outputPath = request['outputPath']! as String;
//   final brightness = request['brightness']! as double;

//   final sourceBytes = File(inputPath).readAsBytesSync();
//   final decoded = image.decodeImage(sourceBytes);
//   if (decoded == null) {
//     throw StateError('The captured page is not a valid image');
//   }

//   final adjusted = image.adjustColor(decoded, brightness: brightness);
//   File(outputPath).writeAsBytesSync(image.encodeJpg(adjusted, quality: 92));
//   return outputPath;
// }
