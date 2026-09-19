import 'dart:io';
import 'dart:typed_data';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
    final extension = path.split('/').last.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'heic', 'heif', 'webp'].contains(extension)) {
      throw const FormatException('Unsupported card image');
    }
    return IdentityCardExport(
      bytes: await File(path).readAsBytes(),
      fileName: 'identity_${front ? 'front' : 'back'}.$extension',
    );
  }

  /// A single page with both complete images, scaled without cropping.
  static Future<IdentityCardExport> card(NationalIdCard card) async {
    final front = await image(card, front: true);
    final back = await image(card, front: false);
    final document = pw.Document(title: 'Identity card');
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text('Front'),
            pw.SizedBox(height: 8),
            pw.Expanded(
              child: pw.Image(
                pw.MemoryImage(front.bytes),
                fit: pw.BoxFit.contain,
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Text('Back'),
            pw.SizedBox(height: 8),
            pw.Expanded(
              child: pw.Image(
                pw.MemoryImage(back.bytes),
                fit: pw.BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
    return IdentityCardExport(
      bytes: await document.save(),
      fileName: 'identity_card.pdf',
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
