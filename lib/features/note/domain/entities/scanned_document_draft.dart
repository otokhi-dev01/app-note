enum ScanPageFilter { color, grayscale, blackAndWhite }

class ScannedPageDraft {
  final String path;
  final int quarterTurns;
  final ScanPageFilter filter;

  const ScannedPageDraft({
    required this.path,
    this.quarterTurns = 0,
    this.filter = ScanPageFilter.color,
  });

  ScannedPageDraft copyWith({
    String? path,
    int? quarterTurns,
    ScanPageFilter? filter,
  }) {
    return ScannedPageDraft(
      path: path ?? this.path,
      quarterTurns: quarterTurns ?? this.quarterTurns,
      filter: filter ?? this.filter,
    );
  }
}

class ScannedDocumentDraft {
  final String title;
  final List<ScannedPageDraft> pages;

  const ScannedDocumentDraft({required this.title, required this.pages});
}
