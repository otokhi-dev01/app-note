/// A Cambodian national identity card captured during the Digital Civic ID
/// (e-KYC) scan flow.
///
/// Field values mirror what the front/back of the physical card and its
/// Machine Readable Zone (MRZ) carry: the chip-encoded ID number, the
/// bearer's name in both Khmer and Latin script, and the standard
/// biographic fields printed on Cambodian NIDs.
class NationalIdCard {
  const NationalIdCard({
    required this.idNumber,
    required this.nameKhmer,
    required this.nameLatin,
    required this.dateOfBirth,
    required this.placeOfBirthKhmer,
    required this.placeOfBirthEnglish,
    required this.currentAddressKhmer,
    required this.currentAddressEnglish,
    required this.expiryDate,
    required this.mrzLines,
    this.validityYears = 10,
    this.chipIntegrityPercent = 100,
    this.frontImagePath,
    this.backImagePath,
  });

  final String idNumber;
  final String nameKhmer;
  final String nameLatin;
  final String dateOfBirth;
  final String placeOfBirthKhmer;
  final String placeOfBirthEnglish;
  final String currentAddressKhmer;
  final String currentAddressEnglish;
  final String expiryDate;

  /// The two printed MRZ rows (ICAO 9303 style), shown verbatim in the
  /// encrypted chip signature block.
  final List<String> mrzLines;
  final int validityYears;
  final int chipIntegrityPercent;
  final String? frontImagePath;
  final String? backImagePath;

  /// [dateOfBirth] parsed back out of its `DD-MM-YYYY` display form, for
  /// callers (like syncing into the Profile screen's ID Information) that
  /// need a real [DateTime] rather than the formatted string. `null` when
  /// the value isn't in that shape.
  DateTime? get dateOfBirthAsDate {
    final parts = dateOfBirth.split('-');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  /// Parses a scan/e-KYC backend response into a [NationalIdCard].
  ///
  /// The key names below are a PROPOSED contract, not a confirmed one — see
  /// `AppConstants.identityApiUrl`. Each field checks a couple of
  /// plausible spellings (camelCase and snake_case) so a small backend
  /// naming difference doesn't silently blank a field, but the exact keys
  /// should be locked down once the real backend response is seen.
  factory NationalIdCard.fromJson(
    Map<String, dynamic> json, {
    String? frontImagePath,
    String? backImagePath,
  }) {
    String pick(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return '';
    }

    final mrzRaw = json['mrzLines'] ?? json['mrz_lines'] ?? json['mrz'];
    final mrzLines = switch (mrzRaw) {
      List<dynamic>() => mrzRaw.map((line) => line.toString()).toList(),
      String() when mrzRaw.isNotEmpty => mrzRaw.split('\n'),
      _ => const <String>[],
    };

    return NationalIdCard(
      idNumber: pick(['idNumber', 'id_number', 'nationalIdNumber']),
      nameKhmer: pick(['nameKhmer', 'name_kh', 'nameKh']),
      nameLatin: pick(['nameLatin', 'name_en', 'nameEn', 'nameLatn']),
      dateOfBirth: _formatDate(
        pick(['dateOfBirth', 'date_of_birth', 'dob']),
      ),
      placeOfBirthKhmer: pick([
        'placeOfBirthKhmer',
        'place_of_birth_kh',
        'pobKh',
      ]),
      placeOfBirthEnglish: pick([
        'placeOfBirthEnglish',
        'place_of_birth_en',
        'pobEn',
      ]),
      currentAddressKhmer: pick([
        'currentAddressKhmer',
        'current_address_kh',
        'addressKh',
      ]),
      currentAddressEnglish: pick([
        'currentAddressEnglish',
        'current_address_en',
        'addressEn',
      ]),
      expiryDate: _formatDate(pick(['expiryDate', 'expiry_date', 'expiry'])),
      mrzLines: mrzLines.isEmpty ? const [''] : mrzLines,
      validityYears:
          int.tryParse(pick(['validityYears', 'validity_years'])) ?? 10,
      chipIntegrityPercent:
          int.tryParse(
            pick(['chipIntegrityPercent', 'chip_integrity_percent']),
          ) ??
          100,
      frontImagePath: frontImagePath,
      backImagePath: backImagePath,
    );
  }

  /// Renders an ISO-ish date (`2030-08-15`, `2030-08-15T00:00:00Z`, ...) as
  /// the `DD-MM-YYYY` format used throughout this screen. Falls back to the
  /// raw string when it isn't a date `DateTime.parse` understands, so an
  /// unexpected backend format degrades to "shown as-is" rather than blank.
  static String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(parsed.day)}-${two(parsed.month)}-${parsed.year}';
  }

  NationalIdCard copyWith({
    String? idNumber,
    String? nameKhmer,
    String? nameLatin,
    String? dateOfBirth,
    String? placeOfBirthKhmer,
    String? placeOfBirthEnglish,
    String? currentAddressKhmer,
    String? currentAddressEnglish,
    String? expiryDate,
    List<String>? mrzLines,
    int? validityYears,
    int? chipIntegrityPercent,
    String? frontImagePath,
    String? backImagePath,
  }) {
    return NationalIdCard(
      idNumber: idNumber ?? this.idNumber,
      nameKhmer: nameKhmer ?? this.nameKhmer,
      nameLatin: nameLatin ?? this.nameLatin,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      placeOfBirthKhmer: placeOfBirthKhmer ?? this.placeOfBirthKhmer,
      placeOfBirthEnglish: placeOfBirthEnglish ?? this.placeOfBirthEnglish,
      currentAddressKhmer: currentAddressKhmer ?? this.currentAddressKhmer,
      currentAddressEnglish:
          currentAddressEnglish ?? this.currentAddressEnglish,
      expiryDate: expiryDate ?? this.expiryDate,
      mrzLines: mrzLines ?? this.mrzLines,
      validityYears: validityYears ?? this.validityYears,
      chipIntegrityPercent: chipIntegrityPercent ?? this.chipIntegrityPercent,
      frontImagePath: frontImagePath ?? this.frontImagePath,
      backImagePath: backImagePath ?? this.backImagePath,
    );
  }
}
