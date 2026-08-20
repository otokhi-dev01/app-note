import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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

/// Writes a single-page PDF containing [imagePath] and returns its path.
///
/// The page takes the image's own aspect ratio instead of being letterboxed
/// onto A4 — a converted screenshot or receipt should come out the shape it
/// went in. [blockId] names the output, so re-converting the same block
/// overwrites its previous PDF rather than piling up files.
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
      pageFormat: PdfPageFormat(
        image.width!.toDouble(),
        image.height!.toDouble(),
      ),
      build: (context) => pw.Image(image, fit: pw.BoxFit.fill),
    ),
  );

  final dir = await _pdfDir();
  final file = File('${dir.path}/$blockId.pdf');
  await file.writeAsBytes(await document.save(), flush: true);
  return file.path;
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
