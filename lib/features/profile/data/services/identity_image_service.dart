import 'dart:io';
import 'dart:typed_data';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:Note/features/profile/domain/entities/national_id_card.dart';

class IdentityCardExport {
  const IdentityCardExport({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

/// Keeps original scan resolution for previews, stored photos, and exports.
abstract final class IdentityImageService {
  static Future<String?> scan() async {
    final images = await CunningDocumentScanner.getPictures(
      noOfPages: 1,
      scannerSource: ScannerSource.cameraAndGallery,
    );
    return images?.firstOrNull;
  }

  static Future<IdentityCardExport> image(
    NationalIdCard card, {
    required bool front,
  }) async {
    final path = front ? card.frontImagePath : card.backImagePath;
    if (path == null) throw const FileSystemException('Missing card image');
    return imageFromPath(path, front: front);
  }

  static Future<IdentityCardExport> imageFromPath(
    String path, {
    required bool front,
  }) async {
    final extension = path.split('/').last.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'heic', 'heif', 'webp'].contains(extension)) {
      throw const FormatException('Unsupported card image');
    }
    return IdentityCardExport(
      bytes: await File(path).readAsBytes(),
      fileName: 'identity_${front ? 'front' : 'back'}.$extension',
    );
  }

  /// Print-ready A4 record with both card sides and all saved document data.
  static Future<IdentityCardExport> card(NationalIdCard card) async {
    Future<pw.Font> font(String name) async =>
        pw.Font.ttf(await rootBundle.load('assets/fonts/$name.ttf'));
    final base = await font('NotoSans-Regular');
    final bold = await font('NotoSans-Bold');
    final khmer = await font('NotoSansKhmer-Regular');
    final khmerBold = await font('NotoSansKhmer-Bold');
    final document = pw.Document(
      title: 'Identity card',
      theme: pw.ThemeData.withFont(
        base: base,
        bold: bold,
        fontFallback: [khmer, khmerBold],
      ),
    );
    final images = <bool, pw.MemoryImage>{};
    for (final front in [true, false]) {
      final path = front ? card.frontImagePath : card.backImagePath;
      if (path == null || path.isEmpty) continue;
      images[front] = pw.MemoryImage((await image(card, front: front)).bytes);
    }

    pw.Widget side(bool front) => pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            front ? 'FRONT' : 'BACK',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            height: 54 * PdfPageFormat.mm,
            width: double.infinity,
            alignment: pw.Alignment.center,
            child: images[front] == null
                ? pw.Text(
                    'Not scanned',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  )
                : pw.Image(images[front]!, fit: pw.BoxFit.contain),
          ),
        ],
      ),
    );
    final details = <(String, String)>[
      ('ID number', card.idNumber),
      ('Name (Khmer)', card.nameKhmer),
      ('Name (Latin)', card.nameLatin),
      ('Date of birth', card.dateOfBirth),
      ('Expiry date', card.expiryDate),
      ('Place of birth (Khmer)', card.placeOfBirthKhmer),
      ('Place of birth (English)', card.placeOfBirthEnglish),
      ('Current address (Khmer)', card.currentAddressKhmer),
      ('Current address (English)', card.currentAddressEnglish),
      ('Validity (years)', '${card.validityYears}'),
      ('Recorded scan integrity', '${card.chipIntegrityPercent}%'),
    ];
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (_) => [
          pw.Text(
            'IDENTITY CARD',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Card images and saved information',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [side(true), pw.SizedBox(width: 16), side(false)],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'IDENTITY INFORMATION',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            data: [
              for (final (label, value) in details)
                [label, value.trim().isEmpty ? 'Not provided' : value],
            ],
            headerCount: 0,
            columnWidths: {
              0: const pw.FixedColumnWidth(145),
              1: const pw.FlexColumnWidth(),
            },
            cellAlignments: {0: pw.Alignment.topLeft, 1: pw.Alignment.topLeft},
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 7,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'MACHINE-READABLE ZONE (MRZ)',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (card.mrzLines.every((line) => line.trim().isEmpty))
            pw.Text('Not provided', style: const pw.TextStyle(fontSize: 9))
          else
            for (final line in card.mrzLines)
              pw.Text(line, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
    final pdfBytes = await document.save();
    final pdfDoc = await pdfx.PdfDocument.openData(pdfBytes);
    final page = await pdfDoc.getPage(1);
    const renderWidth = 1600.0;
    final rendered = await page.render(
      width: renderWidth,
      height: renderWidth * page.height / page.width,
      format: pdfx.PdfPageImageFormat.png,
      backgroundColor: '#FFFFFF',
      forPrint: true,
    );
    await page.close();
    await pdfDoc.close();

    if (rendered == null) {
      throw StateError('Could not render identity card PDF to image');
    }

    return IdentityCardExport(
      bytes: rendered.bytes,
      fileName: 'identity_card.png',
    );
  }

  /// The native save dialog writes the bytes; null means the user cancelled.
  static Future<String?> save(IdentityCardExport export) => FilePicker.saveFile(
    fileName: export.fileName,
    type: FileType.custom,
    allowedExtensions: [export.fileName.split('.').last],
    bytes: export.bytes,
  );
}
