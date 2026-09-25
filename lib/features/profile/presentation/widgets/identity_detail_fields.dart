import 'package:get/get.dart';
import 'package:Note/features/profile/domain/entities/national_id_card.dart';

/// Shared labels and complete values for both identity detail screens.
List<({String label, String value})> identityAdditionalDetails(
  NationalIdCard card,
) {
  final fields = <({String label, String value})>[];
  void add(String label, Object? value) {
    if (value is Map) {
      for (final entry in value.entries) {
        add('$label · ${entry.key}', entry.value);
      }
    } else if (value is List) {
      for (var i = 0; i < value.length; i++) {
        add('$label ${i + 1}', value[i]);
      }
    } else if (value != null && value.toString().trim().isNotEmpty) {
      fields.add((label: label, value: value.toString()));
    }
  }

  for (final entry in {
    'document_type': card.documentType,
    'document_gender': card.gender,
    'document_nationality': card.nationality,
    'document_issuing_country': card.issuingCountry,
    'document_issued_date': card.issuedDate,
    'document_issuing_authority': card.issuingAuthority,
  }.entries) {
    add(entry.key.tr, entry.value);
  }
  for (final entry in card.additionalFields.entries) {
    final label = entry.key
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match[1]} ${match[2]}',
        );
    add(label, entry.value);
  }
  return fields;
}
