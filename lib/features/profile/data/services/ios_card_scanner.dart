import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:Note/core/services/native_media_services.dart';
import 'package:Note/features/profile/domain/entities/card_text_parser.dart';
import 'package:Note/features/profile/domain/entities/credit_card.dart';

class CardTextNotFoundException implements Exception {}

/// Uses the app's existing VisionKit camera and Apple Vision text recognition.
class IosCardScanner {
  Future<CreditCard?> scan() async {
    final paths = await CunningDocumentScanner.getPictures(
      noOfPages: 2,
      scannerSource: ScannerSource.camera,
    );
    if (paths == null || paths.isEmpty) return null;
    try {
      final text = <String>[];
      for (final path in paths) {
        text.add(await NativeMediaServices.recognizeText(path));
      }
      final card = CardTextParser.parse(text.join('\n'));
      if (card == null) throw CardTextNotFoundException();
      return card;
    } finally {
      // Only remove this scan's temporary captures, including on OCR failure.
      for (final path in paths) {
        try {
          await File(path).delete();
        } on FileSystemException {
          // Cleanup must not replace the scan result or original error.
        }
      }
    }
  }
}
