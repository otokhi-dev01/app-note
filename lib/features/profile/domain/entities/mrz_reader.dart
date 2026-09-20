import 'package:Note/features/profile/domain/entities/national_id_card.dart';
import 'package:Note/features/profile/domain/entities/passport_card.dart';

/// Reads a Cambodian national ID's Machine Readable Zone (TD1) or a
/// Passport's MRZ (TD3) out of raw OCR text entirely on-device.
abstract final class MrzReader {
  /// Attempts to find and parse an MRZ inside [ocrText]. Returns `null`
  /// when no plausible MRZ block can be found.
  static NationalIdCard? parse(
    String ocrText, {
    String? frontImagePath,
    String? backImagePath,
  }) {
    final lines = _candidateTd1Lines(ocrText);
    if (lines == null) return null;
    final line1 = lines.$1;
    final line2 = lines.$2;
    final line3 = lines.$3;

    final docNumberRaw = line1.substring(5, 14);
    final docNumberCheck = line1[14];
    if (_checkDigit(docNumberRaw) != int.tryParse(docNumberCheck)) {
      return null;
    }
    final idNumber = docNumberRaw.replaceAll('<', '').trim();

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

  /// Attempts to find and parse a TD3 Passport MRZ inside [ocrText].
  static PassportCard? parsePassport(String ocrText, {String? imagePath}) {
    final lines = _candidateTd3Lines(ocrText);
    if (lines == null) return null;
    final line1 = lines.$1;
    final line2 = lines.$2;

    // --- Line 2: Passport Number (9) + Check (1) + Nationality (3) +
    // DOB (6) + Check (1) + Sex (1) + Expiry (6) + Check (1) + Optional (14) +
    // Composite Check (1). ---
    final passportNumRaw = line2.substring(0, 9);
    final passportNumCheck = line2[9];
    if (_checkDigit(passportNumRaw) != int.tryParse(passportNumCheck)) {
      return null;
    }
    final passportNumber = passportNumRaw.replaceAll('<', '').trim();

    final nationality = line2.substring(10, 13).replaceAll('<', '').trim();

    final dobRaw = line2.substring(13, 19);
    final dobCheck = line2[19];
    final dob = _checkDigit(dobRaw) == int.tryParse(dobCheck)
        ? _expandDate(dobRaw, preferPast: true)
        : null;

    final genderRaw = line2[20];
    final gender = genderRaw == 'F' ? 'Female' : (genderRaw == 'M' ? 'Male' : '');

    final expiryRaw = line2.substring(21, 27);
    final expiryCheck = line2[27];
    final expiry = _checkDigit(expiryRaw) == int.tryParse(expiryCheck)
        ? _expandDate(expiryRaw, preferPast: false)
        : null;

    // --- Line 1: Surname << Given Name ---
    // Format: P<IssuingStateCode Surname << Given Name
    final nameSection = line1.substring(5);
    final names = nameSection.split('<<');
    final surname = names.isNotEmpty ? names[0].replaceAll('<', ' ').trim() : '';
    final givenNames = names.length > 1 ? names[1].replaceAll('<', ' ').trim() : '';
    final fullName = [givenNames, surname].where((s) => s.isNotEmpty).join(' ');

    final issuingCountry = line1.substring(2, 5).replaceAll('<', '').trim();

    return PassportCard(
      passportNumber: passportNumber,
      fullName: fullName,
      dateOfBirth: dob ?? '',
      gender: gender,
      nationality: nationality,
      expiryDate: expiry ?? '',
      issuingCountry: issuingCountry,
      mrzLines: [line1, line2],
      imagePath: imagePath,
    );
  }

  static (String, String, String)? _candidateTd1Lines(String ocrText) {
    final cleaned = _clean(ocrText, length: 30);
    if (cleaned.length < 3) return null;
    final last3 = cleaned.sublist(cleaned.length - 3);
    return (last3[0], last3[1], last3[2]);
  }

  static (String, String)? _candidateTd3Lines(String ocrText) {
    final cleaned = _clean(ocrText, length: 44);
    if (cleaned.length < 2) return null;
    // Look for lines starting with 'P<' or having many '<'
    final candidates = cleaned.where((l) => l.startsWith('P') || l.contains('<<<<')).toList();
    if (candidates.length < 2) return null;
    return (candidates[candidates.length - 2], candidates.last);
  }

  static List<String> _clean(String ocrText, {required int length}) {
    return ocrText
        .split('\n')
        .map((line) => line.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9<]'), ''))
        .where((line) => line.length >= length * 0.7 && line.contains('<'))
        .map((line) {
          if (line.length >= length) return line.substring(0, length);
          return line.padRight(length, '<');
        })
        .toList();
  }

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
