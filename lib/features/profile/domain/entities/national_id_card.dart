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

  String get displayPlaceOfBirth => [
    placeOfBirthKhmer,
    placeOfBirthEnglish,
  ].where((value) => value.trim().isNotEmpty).toSet().join(' / ');
  String get displayCurrentAddress => [
    currentAddressKhmer,
    currentAddressEnglish,
  ].where((value) => value.trim().isNotEmpty).toSet().join('\n');

  Map<String, dynamic> toJson() => {
    'idNumber': idNumber,
    'nameKhmer': nameKhmer,
    'nameLatin': nameLatin,
    'dateOfBirth': dateOfBirth,
    'placeOfBirthKhmer': placeOfBirthKhmer,
    'placeOfBirthEnglish': placeOfBirthEnglish,
    'currentAddressKhmer': currentAddressKhmer,
    'currentAddressEnglish': currentAddressEnglish,
    'expiryDate': expiryDate,
    'mrzLines': mrzLines,
    'validityYears': validityYears,
    'chipIntegrityPercent': chipIntegrityPercent,
    'frontImagePath': frontImagePath,
    'backImagePath': backImagePath,
  };

  /// A partial rescan must not erase previously recognized or edited fields.
  NationalIdCard fillMissingFrom(NationalIdCard? previous) {
    if (previous == null || previous.idNumber != idNumber) return this;
    String fill(String value, String old) => value.trim().isEmpty ? old : value;
    return copyWith(
      nameKhmer: fill(nameKhmer, previous.nameKhmer),
      nameLatin: fill(nameLatin, previous.nameLatin),
      dateOfBirth: fill(dateOfBirth, previous.dateOfBirth),
      placeOfBirthKhmer: fill(placeOfBirthKhmer, previous.placeOfBirthKhmer),
      placeOfBirthEnglish: fill(
        placeOfBirthEnglish,
        previous.placeOfBirthEnglish,
      ),
      currentAddressKhmer: fill(
        currentAddressKhmer,
        previous.currentAddressKhmer,
      ),
      currentAddressEnglish: fill(
        currentAddressEnglish,
        previous.currentAddressEnglish,
      ),
      expiryDate: fill(expiryDate, previous.expiryDate),
      mrzLines: mrzLines.any((line) => line.isNotEmpty)
          ? mrzLines
          : previous.mrzLines,
      frontImagePath: frontImagePath ?? previous.frontImagePath,
      backImagePath: backImagePath ?? previous.backImagePath,
    );
  }

  /// [dateOfBirth] parsed back out of its `DD-MM-YYYY` display form, for
  /// callers (like syncing into the Profile screen's ID Information) that
  /// need a real [DateTime] rather than the formatted string. `null` when
  /// the value isn't in that shape.
  DateTime? get dateOfBirthAsDate => _parseDisplayDate(dateOfBirth);

  /// [expiryDate] parsed the same way — see [dateOfBirthAsDate].
  DateTime? get expiryDateAsDate => _parseDisplayDate(expiryDate);

  static DateTime? _parseDisplayDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
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

    final mrzRaw =
        json['mrzLines'] ??
        json['mrz_lines'] ??
        json['mrz'] ??
        json['MrzLines'] ??
        json['Mrz'] ??
        json['mrzData'] ??
        json['mrz_data'];
    final mrzLines = switch (mrzRaw) {
      List<dynamic>() => mrzRaw.map((line) => line.toString()).toList(),
      String() when mrzRaw.isNotEmpty => mrzRaw.split('\n'),
      _ => const <String>[],
    };

    return NationalIdCard(
      idNumber: pick([
        'idNumber',
        'id_number',
        'nationalIdNumber',
        'national_id_number',
        'id',
        'Id',
        'ID',
        'IdNumber',
        'NationalIdNumber',
        'number',
        'documentNumber',
        'DocumentNumber',
        'document_number',
        'cardNo',
        'card_no',
        'CardNo',
        'idCardNumber',
        'identityNumber',
      ]),
      nameKhmer: pick([
        'nameKhmer',
        'name_kh',
        'nameKh',
        'NameKhmer',
        'NameKh',
        'fullNameKhmer',
        'FullNameKhmer',
        'full_name_khmer',
        'khmerName',
        'KhmerName',
        'khmer_name',
        'nameInKhmer',
      ]),
      nameLatin: pick([
        'nameLatin',
        'name_en',
        'nameEn',
        'nameLatn',
        'NameLatin',
        'NameEn',
        'fullNameLatin',
        'FullNameLatin',
        'full_name_latin',
        'latinName',
        'LatinName',
        'latin_name',
        'fullName',
        'FullName',
        'full_name',
        'name',
        'Name',
        'englishName',
        'EnglishName',
      ]),
      dateOfBirth: _formatDate(
        pick([
          'dateOfBirth',
          'date_of_birth',
          'dob',
          'DateOfBirth',
          'Dob',
          'DOB',
          'birthDate',
          'BirthDate',
          'birth_date',
          'dateBirth',
          'DateBirth',
        ]),
      ),
      placeOfBirthKhmer: pick([
        'placeOfBirthKhmer',
        'place_of_birth_kh',
        'pobKh',
        'PlaceOfBirthKhmer',
        'PlaceOfBirthKh',
        'pobKhmer',
        'PobKhmer',
        'pob_khmer',
        'pob_kh',
      ]),
      placeOfBirthEnglish: pick([
        'placeOfBirthEnglish',
        'place_of_birth_en',
        'pobEn',
        'PlaceOfBirthEnglish',
        'PlaceOfBirthEn',
        'pobEnglish',
        'PobEnglish',
        'pob_english',
        'pob_en',
        'placeOfBirth',
        'PlaceOfBirth',
        'place_of_birth',
        'pob',
      ]),
      currentAddressKhmer: pick([
        'currentAddressKhmer',
        'current_address_kh',
        'addressKh',
        'CurrentAddressKhmer',
        'CurrentAddressKh',
        'addressKhmer',
        'AddressKhmer',
        'address_kh',
      ]),
      currentAddressEnglish: pick([
        'currentAddressEnglish',
        'current_address_en',
        'addressEn',
        'CurrentAddressEnglish',
        'CurrentAddressEn',
        'addressEnglish',
        'AddressEnglish',
        'address_en',
        'address',
        'Address',
        'currentAddress',
        'CurrentAddress',
        'current_address',
      ]),
      expiryDate: _formatDate(
        pick([
          'expiryDate',
          'expiry_date',
          'expiry',
          'ExpiryDate',
          'Expiry',
          'expirationDate',
          'ExpirationDate',
          'expiration_date',
          'validUntil',
          'valid_until',
        ]),
      ),
      mrzLines: mrzLines.isEmpty ? const [''] : mrzLines,
      validityYears:
          int.tryParse(
            pick(['validityYears', 'validity_years', 'ValidityYears', 'validity']),
          ) ??
          10,
      chipIntegrityPercent:
          int.tryParse(
            pick([
              'chipIntegrityPercent',
              'chip_integrity_percent',
              'ChipIntegrityPercent',
              'chipIntegrity',
            ]),
          ) ??
          100,
      frontImagePath:
          (frontImagePath != null && frontImagePath.isNotEmpty)
              ? frontImagePath
              : () {
                  final val = pick([
                    'frontImagePath',
                    'front_image_path',
                    'FrontImagePath',
                    'frontImage',
                    'FrontImage',
                    'front_image',
                    'front',
                    'Front',
                  ]);
                  return val.isEmpty ? null : val;
                }(),
      backImagePath:
          (backImagePath != null && backImagePath.isNotEmpty)
              ? backImagePath
              : () {
                  final val = pick([
                    'backImagePath',
                    'back_image_path',
                    'BackImagePath',
                    'backImage',
                    'BackImage',
                    'back_image',
                    'back',
                    'Back',
                  ]);
                  return val.isEmpty ? null : val;
                }(),
    );
  }

  /// Renders an ISO-ish date (`2030-08-15`, `2030-08-15T00:00:00Z`, ...) or
  /// `DD/MM/YYYY`, `YYYY/MM/DD` as the `DD-MM-YYYY` format used throughout
  /// this screen.
  static String _formatDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    // Match DD-MM-YYYY or DD/MM/YYYY
    final ddmmyyyy = RegExp(r'^(\d{2})[/-](\d{2})[/-](\d{4})$');
    final matchDD = ddmmyyyy.firstMatch(trimmed);
    if (matchDD != null) {
      return '${matchDD.group(1)}-${matchDD.group(2)}-${matchDD.group(3)}';
    }

    // Match YYYY-MM-DD or YYYY/MM/DD
    final yyyymmdd = RegExp(r'^(\d{4})[/-](\d{2})[/-](\d{2})');
    final matchYYYY = yyyymmdd.firstMatch(trimmed);
    if (matchYYYY != null) {
      return '${matchYYYY.group(3)}-${matchYYYY.group(2)}-${matchYYYY.group(1)}';
    }

    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return trimmed;
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
