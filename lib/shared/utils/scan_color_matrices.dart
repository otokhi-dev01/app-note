import 'package:flutter/widgets.dart';

/// Live-preview approximation of [note_editor_scan_filter_gray] — the real bake
/// happens in `scan_page_processor.dart` via `image.grayscale`. Shared so the
/// document camera's live preview and the review page's cycle-filter preview
/// render the same look.
const grayscaleColorMatrix = <double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

/// Live-preview approximation of [note_editor_scan_filter_bw] — the real bake
/// happens in `scan_page_processor.dart` via `image.luminanceThreshold`.
const highContrastGrayscaleColorMatrix = <double>[
  0.34,
  1.14,
  0.12,
  0,
  -75,
  0.34,
  1.14,
  0.12,
  0,
  -75,
  0.34,
  1.14,
  0.12,
  0,
  -75,
  0,
  0,
  0,
  1,
  0,
];

const grayscaleColorFilter = ColorFilter.matrix(grayscaleColorMatrix);
const highContrastGrayscaleColorFilter = ColorFilter.matrix(
  highContrastGrayscaleColorMatrix,
);
