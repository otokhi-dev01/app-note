/// A passport document captured or manually entered.
class PassportCard {
  const PassportCard({
    required this.passportNumber,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.nationality,
    required this.expiryDate,
    this.issuedDate = '',
    this.issuingCountry = '',
    required this.mrzLines,
    this.imagePath,
  });

  final String passportNumber;
  final String fullName;
  final String dateOfBirth;
  final String gender;
  final String nationality;
  final String expiryDate;
  final String issuedDate;
  final String issuingCountry;

  /// The two printed MRZ rows (ICAO 9303 "TD3" style).
  final List<String> mrzLines;
  final String? imagePath;

  Map<String, dynamic> toJson() => {
    'passportNumber': passportNumber,
    'fullName': fullName,
    'dateOfBirth': dateOfBirth,
    'gender': gender,
    'nationality': nationality,
    'expiryDate': expiryDate,
    'issuedDate': issuedDate,
    'issuingCountry': issuingCountry,
    'mrzLines': mrzLines,
    'imagePath': imagePath,
  };

  factory PassportCard.fromJson(Map<String, dynamic> json, {String? imagePath}) {
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

    return PassportCard(
      passportNumber: pick(['passportNumber', 'passport_number', 'documentNumber']),
      fullName: pick(['fullName', 'full_name', 'name']),
      dateOfBirth: _formatDate(pick(['dateOfBirth', 'date_of_birth', 'dob'])),
      gender: pick(['gender', 'sex']),
      nationality: pick(['nationality']),
      expiryDate: _formatDate(pick(['expiryDate', 'expiry_date', 'expiry'])),
      issuedDate: _formatDate(pick(['issuedDate', 'issued_date', 'issued'])),
      issuingCountry: pick(['issuingCountry', 'issuing_country', 'country']),
      mrzLines: mrzLines,
      imagePath: imagePath ?? pick(['imagePath', 'image_path']),
    );
  }

  static String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(parsed.day)}-${two(parsed.month)}-${parsed.year}';
  }

  DateTime? get dateOfBirthAsDate => _parseDisplayDate(dateOfBirth);
  DateTime? get expiryDateAsDate => _parseDisplayDate(expiryDate);
  DateTime? get issuedDateAsDate => _parseDisplayDate(issuedDate);

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

  PassportCard copyWith({
    String? passportNumber,
    String? fullName,
    String? dateOfBirth,
    String? gender,
    String? nationality,
    String? expiryDate,
    String? issuedDate,
    String? issuingCountry,
    List<String>? mrzLines,
    String? imagePath,
  }) {
    return PassportCard(
      passportNumber: passportNumber ?? this.passportNumber,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      nationality: nationality ?? this.nationality,
      expiryDate: expiryDate ?? this.expiryDate,
      issuedDate: issuedDate ?? this.issuedDate,
      issuingCountry: issuingCountry ?? this.issuingCountry,
      mrzLines: mrzLines ?? this.mrzLines,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
