import 'package:Note/features/profile/domain/entities/mrz_reader.dart';

/// Conservative OCR signals for automatic capture, not identity verification.
abstract final class IdentityScanRecognition {
  static String? candidate(String text, {required bool front}) {
    if (!front) {
      final card = MrzReader.parse(text);
      if (card == null ||
          card.idNumber.isEmpty ||
          card.nameLatin.isEmpty ||
          card.dateOfBirthAsDate == null ||
          card.expiryDateAsDate == null) {
        return null;
      }
      return card.mrzLines.join('\n');
    }
    // Avoid accepting the back as the front, or an arbitrary receipt/card.
    if (MrzReader.parse(text) != null) return null;
    final upper = text.toUpperCase();
    if (!upper.contains('IDENTITY') &&
        !upper.contains('CAMBODIA') &&
        !text.contains('អត្តសញ្ញាណ')) {
      return null;
    }
    final number = RegExp(
      r'(?<!\d)\d{3}[ ]?\d{3}[ ]?\d{3}(?!\d)',
    ).firstMatch(text)?.group(0)?.replaceAll(' ', '');
    final date = RegExp(r'\b\d{2}[./-]\d{2}[./-]\d{4}\b').firstMatch(text);
    return number == null || date == null ? null : '$number:${date.group(0)}';
  }
}
