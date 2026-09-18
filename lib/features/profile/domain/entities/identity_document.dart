/// Fields accepted by POST /upload-document. Optional values are omitted.
class IdentityDocument {
  const IdentityDocument({
    required this.documentType,
    required this.documentNumber,
    this.fullName = '',
    this.dateOfBirth,
    this.gender = '',
    this.nationality = '',
    this.issuingCountry = '',
    this.issuedDate,
    this.expiryDate,
    this.issuingAuthority = '',
    this.frontImagePath,
    this.backImagePath,
  });

  final String documentType;
  final String documentNumber;
  final String fullName;
  final DateTime? dateOfBirth;
  final String gender;
  final String nationality;
  final String issuingCountry;
  final DateTime? issuedDate;
  final DateTime? expiryDate;
  final String issuingAuthority;
  final String? frontImagePath;
  final String? backImagePath;
}
