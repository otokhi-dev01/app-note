import 'package:Note/features/profile/domain/entities/national_id_card.dart';

/// Reads a Cambodian national ID's Machine Readable Zone (the 3-line ICAO
/// 9303 "TD1" block printed on the back of the card) out of raw OCR text,
/// entirely on-device — no BlinkID license and no backend call required.
///
/// This exists because the on-device text recognizer this app already uses
/// for card scanning (`NativeMediaServices.recognizeText` — Apple Vision on
/// iOS, Google ML Kit's *Latin* recognizer on Android; see
/// `MainActivity.kt` / `AppDelegate.swift`) only reads Latin/numeric script.
/// The MRZ is exactly that: fixed-width, all-caps A-Z/0-9/`<` text, by
/// design readable by any OCR engine — unlike the Khmer-script name/address
/// fields printed on the front, which this recognizer cannot read at all.
/// So this only ever fills what the MRZ actually carries (ID number, date of
/// birth, expiry date, the Latin name) and leaves the Khmer-script fields
/// for manual entry, same as a normal manual edit does today.
///
/// Each numeric field is only trusted when its own ICAO check digit
/// validates — see [_checkDigit]. A field that doesn't check out is left
/// blank rather than shown with unverified (possibly wrong) data.
abstract final class MrzReader {
  /// Attempts to find and parse a TD1 MRZ inside [ocrText]. Returns `null`
  /// when no plausible 3-line MRZ block — specifically, one whose document
  /// number check digit validates — can be found, so callers can fall back
  /// to manual entry rather than show a guess.
  static NationalIdCard? parse(
    String ocrText, {
    String? frontImagePath,
    String? backImagePath,
  }) {
    final lines = _candidateLines(ocrText);
    if (lines == null) return null;
    final line1 = lines.$1;
    final line2 = lines.$2;
    final line3 = lines.$3;

    // --- Line 1: document code (2) + issuing state (3) + doc number (9) +
    // its check digit (1) + optional data (15). ---
    final docNumberRaw = line1.substring(5, 14);
    final docNumberCheck = line1[14];
    if (_checkDigit(docNumberRaw) != int.tryParse(docNumberCheck)) {
      // No validated document number means this almost certainly isn't a
      // real MRZ (or the OCR was too noisy to trust) — bail out entirely
      // rather than hand back a partially-invented card.
      return null;
    }
    final idNumber = docNumberRaw.replaceAll('<', '').trim();

    // --- Line 2: DOB (6) + check (1) + sex (1) + expiry (6) + check (1) +
    // nationality (3) + optional (11) + composite check (1). The composite
    // check is intentionally not validated — its exact field span is easy
    // to get subtly wrong from memory, and skipping it costs nothing since
    // it gates no data this parser extracts. ---
    final dobRaw = line2.substring(0, 6);
    final dobCheck = line2[6];
    final expiryRaw = line2.substring(8, 14);
    final expiryCheck = line2[14];

    final dob = _checkDigit(dobRaw) == int.tryParse(dobCheck)
        ? _expandDate(dobRaw, preferPast: true)
        : null;
    final expiry = _checkDigit(expiryRaw) == int.tryParse(expiryCheck)
        ? _expandDate(expiryRaw, preferPast: false)
        : null;

    // --- Line 3: SURNAME<<GIVEN<NAMES<<<... — no check digit exists for
    // this field in TD1, so it's taken best-effort. ---
    final nameLatin = line3
        .split('<<')
        .map((part) => part.replaceAll('<', ' ').trim())
        .where((part) => part.isNotEmpty)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return NationalIdCard(
      idNumber: idNumber,
      nameKhmer: '',
      nameLatin: nameLatin,
      dateOfBirth: dob ?? '',
      placeOfBirthKhmer: '',
      placeOfBirthEnglish: '',
      currentAddressKhmer: '',
      currentAddressEnglish: '',
      expiryDate: expiry ?? '',
      mrzLines: [line1, line2, line3],
      frontImagePath: frontImagePath,
      backImagePath: backImagePath,
    );
  }

  /// Cleans OCR'd text into lines and picks the 3 most MRZ-like ones — rows
  /// that, once whitespace and stray punctuation are stripped, are close to
  /// the fixed 30-character TD1 width and contain the `<` fill character
  /// (a strong signal, since normal printed text essentially never OCRs
  /// with `<`). Each candidate is right-padded/truncated to exactly 30
  /// characters so a dropped or extra character from noisy OCR doesn't
  /// shift every field after it.
  static (String, String, String)? _candidateLines(String ocrText) {
    final cleaned = ocrText
        .split('\n')
        .map(
          (line) => line
              .toUpperCase()
              .replaceAll(RegExp(r'[^A-Z0-9<]'), ''),
        )
        .where((line) => line.length >= 20 && line.contains('<'))
        .map((line) {
          if (line.length >= 30) return line.substring(0, 30);
          return line.padRight(30, '<');
        })
        .toList();
    if (cleaned.length < 3) return null;
    // The MRZ block is contiguous; the last 3 qualifying lines are the most
    // likely real MRZ rows when other printed text also happens to match.
    final last3 = cleaned.sublist(cleaned.length - 3);
    return (last3[0], last3[1], last3[2]);
  }

  /// The ICAO 9303 check digit: each character's value (`0`-`9` as-is,
  /// `A`-`Z` as 10-35, `<` as 0) weighted by a repeating 7/3/1 cycle,
  /// summed and taken mod 10. Returns `null` when [field] contains a
  /// character outside `A-Z0-9<`, which should never happen after
  /// [_candidateLines]'s cleaning but is guarded defensively.
  static int? _checkDigit(String field) {
    const weights = [7, 3, 1];
    var sum = 0;
    for (var i = 0; i < field.length; i++) {
      final c = field.codeUnitAt(i);
      final int value;
      if (c >= 0x30 && c <= 0x39) {
        value = c - 0x30;
      } else if (c >= 0x41 && c <= 0x5A) {
        value = c - 0x41 + 10;
      } else if (field[i] == '<') {
        value = 0;
      } else {
        return null;
      }
      sum += value * weights[i % 3];
    }
    return sum % 10;
  }

  /// Expands an MRZ `YYMMDD` field to this app's `DD-MM-YYYY` display form
  /// (see `NationalIdCard._formatDate`), resolving the 2-digit year's
  /// century. A birth date must be in the past, so when the current-century
  /// reading would land in the future, the previous century is used
  /// instead; an expiry date on a card being scanned today is assumed to
  /// fall within the current century outright. Returns `null` when the
  /// digits don't form a real calendar date.
  static String? _expandDate(String yymmdd, {required bool preferPast}) {
    final yy = int.tryParse(yymmdd.substring(0, 2));
    final mm = int.tryParse(yymmdd.substring(2, 4));
    final dd = int.tryParse(yymmdd.substring(4, 6));
    if (yy == null || mm == null || dd == null) return null;
    if (mm < 1 || mm > 12) return null;

    final now = DateTime.now();
    final currentCentury = (now.year ~/ 100) * 100;
    var year = currentCentury + yy;
    if (preferPast && year > now.year) year -= 100;

    final daysInMonth = DateTime(year, mm + 1, 0).day;
    if (dd < 1 || dd > daysInMonth) return null;

    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dd)}-${two(mm)}-$year';
  }
}
