import 'package:Note/features/profile/domain/entities/national_id_card.dart';

/// Reads labelled printed fields. MRZ contains no birthplace or address.
abstract final class IdentityPrintedTextReader {
  static final _khmer = RegExp(r'[\u1780-\u17FF]');
  static String _khmerLabel(String label) =>
      label.split('').map(RegExp.escape).join(r'[\s\u200B]*');
  static final _labels = RegExp(
    [
      '(?<birth>${['ទីកន្លែងកំណើត', 'កន្លែងកំណើត'].map(_khmerLabel).join('|')}|PLACE\\s+OF\\s+BIRTH|BIRTH\\s*PLACE)',
      '(?<address>${['អាសយដ្ឋានបច្ចុប្បន្ន', 'ទីលំនៅបច្ចុប្បន្ន', 'អាសយដ្ឋាន', 'ទីលំនៅ'].map(_khmerLabel).join('|')}|CURRENT\\s+(?:ADDRESS|RESIDENCE)|ADDRESS|RESIDENCE)',
      '(?<name>${['គោត្តនាមនិងនាម', 'នាមត្រកូលនិងនាមខ្លួន', 'គោត្តនាមនាម'].map(_khmerLabel).join('|')})',
      '(?<stop>${['ថ្ងៃខែឆ្នាំកំណើត', 'ភេទ', 'សញ្ជាតិ', 'សុពលភាព', 'ហត្ថលេខា', 'កម្ពស់', 'ថ្ងៃផុតកំណត់'].map(_khmerLabel).join('|')}|DATE\\s+OF\\s+BIRTH|DATE\\s+OF\\s+EXPIRY|EXPIRY|VALIDITY|SEX|GENDER|NATIONALITY|SIGNATURE|HEIGHT|ID\\s*(?:NO|NUMBER))',
    ].join('|'),
    caseSensitive: false,
  );

  static NationalIdCard enrich(NationalIdCard card, String text) {
    final clean = text.replaceAll('\u200B', '').replaceAll('\r', '');
    final matches = _labels.allMatches(clean).toList();
    final values = <String, String>{};
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      if (match.namedGroup('stop') != null) continue;
      final end = i + 1 < matches.length ? matches[i + 1].start : clean.length;
      final lines = clean.substring(match.end, end).split('\n');
      final parts = <String>[];
      for (final raw in lines) {
        final line = raw
            .replaceAll(RegExp(r'^[\s:៖/|.\-]+|[\s/|]+$'), '')
            .trim();
        if (line.contains('<<') ||
            RegExp(r'^I[<A-Z][A-Z<]{3}[A-Z0-9<]{9}[0-9]').hasMatch(line) ||
            RegExp(r'^\d{6}[MF\d]').hasMatch(line)) {
          break;
        }
        if (line.isNotEmpty) parts.add(line);
        if (parts.length == 3) break;
      }
      final value = parts.join(' ').trim();
      if (value.isEmpty || value.length > 240) continue;
      final kind = match.namedGroup('birth') != null
          ? 'birth'
          : match.namedGroup('address') != null
          ? 'address'
          : 'name';
      final script = _khmer.hasMatch(value) ? 'Khmer' : 'English';
      if (kind == 'name' && script != 'Khmer') continue;
      values.putIfAbsent('$kind$script', () => value);
    }
    return card.copyWith(
      nameKhmer: values['nameKhmer'] ?? (card.nameKhmer.isEmpty ? null : card.nameKhmer),
      placeOfBirthKhmer: values['birthKhmer'] ?? (card.placeOfBirthKhmer.isEmpty ? null : card.placeOfBirthKhmer),
      placeOfBirthEnglish: values['birthEnglish'] ?? (card.placeOfBirthEnglish.isEmpty ? null : card.placeOfBirthEnglish),
      currentAddressKhmer: values['addressKhmer'] ?? (card.currentAddressKhmer.isEmpty ? null : card.currentAddressKhmer),
      currentAddressEnglish: values['addressEnglish'] ?? (card.currentAddressEnglish.isEmpty ? null : card.currentAddressEnglish),
    );
  }
}
