import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pdfx;

/// Building an image-backed PDF attachment, and getting back to the picture it
/// was built from.
///
/// A converted PDF keeps a copy of its source image on device so "Edit" can
/// re-open the original in the markup editor and rebuild the document from the
/// result — the PDF itself is treated as a rendered output, never as the thing
/// being edited.
///
/// The copy is filed under the owning block's id rather than being recorded on
/// the block. A block's `localPath` never reaches the server
/// (`NoteBlockMapper.toJson` drops it by design) but its `id` does, so keying
/// off the id is the only pointer that still resolves after a note has made a
/// round trip through the backend.

/// `<documents>/note_pdfs`, created on first use.
Future<Directory> _pdfDir() async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/note_pdfs');
  if (!dir.existsSync()) await dir.create(recursive: true);
  return dir;
}

/// `.jpg` from `/tmp/…/photo.jpg`, or `''` when there's no extension. Only
/// looks after the last `/` so a dot in a parent directory isn't mistaken for
/// one.
String _extensionOf(String path) {
  final dot = path.lastIndexOf('.');
  final slash = path.lastIndexOf('/');
  return dot > slash ? path.substring(dot) : '';
}

Future<pw.ThemeData> _loadImagePdfTheme() async {
  Future<pw.Font> load(String asset) async {
    final data = await rootBundle.load(asset);
    return pw.Font.ttf(data);
  }

  final base = await load('assets/fonts/NotoSans-Regular.ttf');
  final bold = await load('assets/fonts/NotoSans-Bold.ttf');
  final khmer = await load('assets/fonts/NotoSansKhmer-Regular.ttf');
  final khmerBold = await load('assets/fonts/NotoSansKhmer-Bold.ttf');

  return pw.ThemeData.withFont(
    base: base,
    bold: bold,
    fontFallback: [khmer, khmerBold],
  );
}

/// Writes a single-page PDF containing [imagePath] and returns its path.
///
/// Standardized to A4 format with margins, like a PDF printer. [blockId] names
/// the output, so re-converting the same block overwrites its previous PDF
/// rather than piling up files.
Future<String> buildImagePdf({
  required String imagePath,
  required String blockId,
  String? title,
}) async {
  final bytes = await File(imagePath).readAsBytes();
  final image = pw.MemoryImage(bytes);

  final document = pw.Document(title: title);
  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) =>
          pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
    ),
  );

  final dir = await _pdfDir();
  final file = File('${dir.path}/$blockId.pdf');
  await file.writeAsBytes(await document.save(), flush: true);
  return file.path;
}

/// Writes a multi-page PDF, one page per image in [imagePaths] in order, and
/// returns its path.
///
/// Standardized to A4 format with margins. Multi-page document scans are
/// rendered as a cohesive document where each page fits into the print area.
/// When [showTitle] is true, [title] and [createdAt] form a printed header on
/// every page. [showPageNumbers] adds a `Page 1 of 3`-style footer.
Future<String> buildMultiPageImagePdf({
  required List<String> imagePaths,
  required String blockId,
  String? title,
  bool showTitle = false,
  DateTime? createdAt,
  bool showPageNumbers = false,
  String pageLabel = 'Page',
  String ofLabel = 'of',
}) async {
  final visibleTitle = title?.trim() ?? '';
  final dateTime = createdAt == null
      ? ''
      : DateFormat('MMM d, yyyy  •  h:mm a').format(createdAt.toLocal());
  final document = pw.Document(
    title: visibleTitle,
    theme: await _loadImagePdfTheme(),
  );
  for (var index = 0; index < imagePaths.length; index++) {
    final imagePath = imagePaths[index];
    final bytes = await File(imagePath).readAsBytes();
    final image = pw.MemoryImage(bytes);
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            if (showTitle && visibleTitle.isNotEmpty) ...[
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      visibleTitle,
                      maxLines: 2,
                      style: pw.TextStyle(
                        fontSize: 17,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  if (dateTime.isNotEmpty) ...[
                    pw.SizedBox(width: 16),
                    pw.Text(
                      dateTime,
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey400, thickness: 0.6),
              pw.SizedBox(height: 14),
            ],
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
                ),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Center(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
              ),
            ),
            if (showPageNumbers) ...[
              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColors.grey400, thickness: 0.6),
              pw.SizedBox(height: 6),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  '$pageLabel ${index + 1} $ofLabel ${imagePaths.length}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  final dir = await _pdfDir();
  final file = File('${dir.path}/$blockId.pdf');
  await file.writeAsBytes(await document.save(), flush: true);
  return file.path;
}

/// Rasterizes every page of [pdfPath] to a temporary PNG so an image-only
/// editor can edit a PDF without dropping the document's remaining pages.
///
/// The caller owns the returned files and should delete them after rebuilding
/// the PDF.
Future<List<String>> renderPdfPagesForImageEditing(String pdfPath) async {
  final outputDirectory = await getTemporaryDirectory();
  final token = DateTime.now().microsecondsSinceEpoch;
  final renderedPaths = <String>[];
  final document = await pdfx.PdfDocument.openFile(pdfPath);

  try {
    for (var pageNumber = 1; pageNumber <= document.pagesCount; pageNumber++) {
      pdfx.PdfPage? page;
      try {
        page = await document.getPage(pageNumber);
        const renderWidth = 1600.0;
        final rendered = await page.render(
          width: renderWidth,
          height: renderWidth * page.height / page.width,
          format: pdfx.PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
          forPrint: true,
        );
        if (rendered == null) {
          throw StateError('Could not render PDF page $pageNumber');
        }

        final output = File(
          '${outputDirectory.path}/pdf_edit_${token}_page_$pageNumber.png',
        );
        await output.writeAsBytes(rendered.bytes, flush: true);
        renderedPaths.add(output.path);
      } finally {
        if (page != null && !page.isClosed) await page.close();
      }
    }
    return renderedPaths;
  } catch (_) {
    for (final path in renderedPaths) {
      try {
        await File(path).delete();
      } catch (_) {
        // Best-effort cleanup for temporary rendered pages.
      }
    }
    rethrow;
  } finally {
    if (!document.isClosed) await document.close();
  }
}

/// Keeps [imagePath] as the editable original behind [blockId]'s PDF.
///
/// Copied rather than referenced because the picture it comes from is usually
/// in a cache directory the OS is free to clear, and because converting
/// replaces the image block outright — without its own copy the source would
/// be deleted along with the block it used to belong to.
Future<String> storePdfSourceImage({
  required String imagePath,
  required String blockId,
}) async {
  final dir = await _pdfDir();
  // Read before clearing, not `copy` after: on a re-convert the incoming file
  // can be the stored source itself, and deleting it first would leave
  // nothing to copy from.
  final bytes = await File(imagePath).readAsBytes();
  await _deleteSourceImages(blockId);
  final dest = File('${dir.path}/${blockId}_source${_extensionOf(imagePath)}');
  await dest.writeAsBytes(bytes, flush: true);
  return dest.path;
}

/// Whether [fileName] is a stored source image belonging to [blockId].
///
/// Matched on `<id>_source.` including the dot rather than on a bare `<id>`
/// prefix: server-assigned block ids look like `att_1`, so a loose prefix
/// would also match `att_12`'s files and let one block's edit clobber
/// another's original.
bool _isSourceOf(String fileName, String blockId) =>
    fileName.startsWith('${blockId}_source.');

/// The stored original behind [blockId]'s PDF, or `null` if this device
/// doesn't have one — a PDF attached from Files, or one converted on another
/// device, has no source here and simply isn't editable.
Future<String?> findPdfSourceImage(String blockId) async {
  final dir = await _pdfDir();
  await for (final entity in dir.list()) {
    if (entity is File && _isSourceOf(entity.uri.pathSegments.last, blockId)) {
      return entity.path;
    }
  }
  return null;
}

/// Clears everything [blockId] owns in here — the rendered PDF and the source
/// image behind it.
///
/// Called before storing a new source (the extension may differ, so
/// overwriting by name isn't enough to avoid leaving a stale `_source.png`
/// beside a fresh `_source.jpg`) and when the block itself is deleted.
Future<void> deletePdfFiles(String blockId) async {
  final dir = await _pdfDir();
  await for (final entity in dir.list()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (!_isSourceOf(name, blockId) && name != '$blockId.pdf') continue;
    try {
      await entity.delete();
    } catch (_) {
      // A leftover we can't clear isn't worth failing the caller over.
    }
  }
}

/// Clears just the source image(s), leaving the rendered PDF alone — the
/// store path runs after the new PDF has already been written, so wiping
/// everything there would delete the document it was called to back.
Future<void> _deleteSourceImages(String blockId) async {
  final dir = await _pdfDir();
  await for (final entity in dir.list()) {
    if (entity is File && _isSourceOf(entity.uri.pathSegments.last, blockId)) {
      try {
        await entity.delete();
      } catch (_) {
        // Same as above: not worth failing a conversion over.
      }
    }
  }
}

/// True when [name] looks like a PDF — the signal the attachment tile uses to
/// decide whether to offer the "edit the original" affordance.
bool looksLikePdf(String? name) =>
    name != null && name.trim().toLowerCase().endsWith('.pdf');
