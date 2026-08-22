import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:Note/core/utils/note_snippet.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';

/// The `pdf` package's built-in Helvetica only covers ASCII — no curly
/// quotes (common from iOS auto-correct), no Khmer, nothing outside Latin-1.
/// Bundling Noto Sans (Latin, with a real U+2019) plus Noto Sans Khmer as a
/// fallback covers both scripts this bilingual app actually needs, since a
/// PDF has no equivalent of the OS-level font substitution that's why the
/// exact same text renders fine on-screen in Poppins despite Poppins itself
/// not covering Khmer either.
Future<pw.ThemeData> _loadPdfTheme() async {
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

/// Exporting a whole note — folder, title, and every block in order — as a
/// single printable PDF, distinct from [image_pdf.dart]'s per-attachment
/// image↔PDF conversion (that one turns a single picture into a document;
/// this one turns the whole note into one).
///
/// Building the PDF itself never touches the network: every image/drawing
/// block that should appear must already be resolved to a local file and
/// passed in via [resolvedImagePaths] (block id → path) — the caller
/// downloads any remote-only attachments first, same as
/// `NoteDetailController.cacheAttachmentForEditing` already does for the
/// image editor.
Future<String> buildNotePdf({
  required String folderName,
  required String title,
  required DateTime date,
  required List<NoteBlock> blocks,
  required Map<String, String> resolvedImagePaths,
}) async {
  final document = pw.Document(title: title, theme: await _loadPdfTheme());

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      header: folderName.trim().isEmpty
          ? null
          : (context) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text(
                folderName.trim().toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                  letterSpacing: 1.1,
                ),
              ),
            ),
      build: (context) => [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          DateFormat("MMMM d, yyyy 'at' h:mm a").format(date),
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 16),
        ...blocks
            .map((block) => _buildBlockWidget(block, resolvedImagePaths))
            .whereType<pw.Widget>(),
      ],
    ),
  );

  final dir = await getTemporaryDirectory();
  var safeName = title
      .trim()
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '_');
  if (safeName.length > 60) safeName = safeName.substring(0, 60);
  final fileName = safeName.isEmpty ? 'Note' : safeName;
  final path =
      '${dir.path}/${fileName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final file = File(path);
  await file.writeAsBytes(await document.save(), flush: true);
  return path;
}

pw.Widget? _buildBlockWidget(NoteBlock block, Map<String, String> images) {
  switch (block) {
    case TextBlock(:final text, :final style):
      final flat = NoteSnippet.plainText(text);
      if (flat.isEmpty) return null;
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Text(flat, style: _textStyleFor(style)),
      );

    case ChecklistBlock(:final items):
      if (items.isEmpty) return null;
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            for (final item in items)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Drawn, not a ☑/☐ glyph: those live in the Symbols
                    // block, which neither bundled font covers, so they'd
                    // hit the exact "no font to draw this character"
                    // failure this whole export was just fixed for.
                    pw.Container(
                      width: 9,
                      height: 9,
                      margin: const pw.EdgeInsets.only(top: 2, right: 6),
                      decoration: pw.BoxDecoration(
                        color: item.checked ? PdfColors.grey700 : null,
                        border: pw.Border.all(
                          color: PdfColors.grey700,
                          width: 0.8,
                        ),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(2),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        item.text,
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: item.checked
                              ? PdfColors.grey500
                              : PdfColors.black,
                          decoration: item.checked
                              ? pw.TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );

    case TableBlock(:final rows):
      if (rows.isEmpty) return null;
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          children: [
            for (final row in rows)
              pw.TableRow(
                children: [
                  for (final cell in row)
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(cell, style: const pw.TextStyle(fontSize: 10)),
                    ),
                ],
              ),
          ],
        ),
      );

    // Image attachments and drawings render as the picture itself when a
    // local file was resolved for them; anything else (a resolution that
    // failed, or a non-image attachment like a file/audio recording that
    // was never a candidate for resolution) falls back to naming it, so the
    // page reflects that something was there even if it can't be drawn.
    case AttachmentBlock():
      final path = images[block.id];
      if (path == null) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Text(
            '[${block.displayName}]',
            style: pw.TextStyle(
              fontSize: 10,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey600,
            ),
          ),
        );
      }
      return _imageWidget(path);

    case DrawingBlock():
      final path = images[block.id];
      if (path == null) return null;
      return _imageWidget(path);
  }
}

pw.Widget _imageWidget(String path) {
  final bytes = File(path).readAsBytesSync();
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 14),
    child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
  );
}

pw.TextStyle _textStyleFor(String style) => switch (style) {
  'title' => pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
  'heading' => pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
  'subheading' => pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
  _ => const pw.TextStyle(fontSize: 11),
};
