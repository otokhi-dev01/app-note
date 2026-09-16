import 'package:Note/features/profile/domain/entities/credit_card.dart';

/// Extracts editable card details from OCR text. Missing fields stay empty.
abstract final class CardTextParser {
  static CreditCard? parse(String text) {
    final lines = text.split(RegExp(r'[\r\n]+')).map((s) => s.trim()).toList();
    String? number;
    final numberPattern = RegExp(r'(?<!\d)(?:\d[ \t-]*){12,18}\d(?!\d)');
    for (final line in lines) {
      for (final match in numberPattern.allMatches(line)) {
        final candidate = match[0]!.replaceAll(RegExp(r'\D'), '');
        if (isValidNumber(candidate)) {
          number = candidate;
          break;
        }
      }
      if (number != null) break;
    }
    if (number == null) return null;

    final datePattern = RegExp(
      r'\b(0?[1-9]|1[0-2])\s*[/\-]\s*(20\d{2}|\d{2})\b',
    );
    RegExpMatch? expiry;
    for (final line in lines) {
      if (RegExp(r'VALID\s+FROM|ISSUED', caseSensitive: false).hasMatch(line)) {
        continue;
      }
      final dates = datePattern.allMatches(line).toList();
      if (dates.isNotEmpty) expiry = dates.last;
      if (expiry != null &&
          RegExp(r'EXP|THRU|UNTIL', caseSensitive: false).hasMatch(line)) {
        break;
      }
    }

    var name = '';
    final nameLabel = RegExp(
      r'^(?:CARDHOLDER(?:\s+NAME)?|NAME)\s*:?\s*',
      caseSensitive: false,
    );
    for (var i = 0; i < lines.length; i++) {
      if (!nameLabel.hasMatch(lines[i])) continue;
      final value = lines[i].replaceFirst(nameLabel, '').trim();
      final candidate = value.isNotEmpty
          ? value
          : (i + 1 < lines.length ? lines[i + 1] : '');
      if (RegExp(r"^[A-Za-z][A-Za-z .'-]+$").hasMatch(candidate)) {
        name = candidate;
      }
      break;
    }

    final securityCode =
        RegExp(
          r'\b(?:CVV2?|CVC2?|CID|SECURITY CODE)\s*:?\s*(\d{3,4})\b',
          caseSensitive: false,
        ).firstMatch(text)?[1] ??
        '';
    final year = expiry?[2] ?? '';
    return CreditCard(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      cardNumber: number,
      cardholderName: name,
      expiryMonth: expiry?[1]?.padLeft(2, '0') ?? '',
      expiryYear: year.length == 2 ? '20$year' : year,
      cvv: securityCode,
      cardBrand: _brand(number),
    );
  }

  static bool isValidNumber(String input) {
    final number = input.replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^\d{13,19}$').hasMatch(number) ||
        RegExp(r'^(\d)\1+$').hasMatch(number)) {
      return false;
    }
    var sum = 0;
    var doubleDigit = false;
    for (var i = number.length - 1; i >= 0; i--) {
      var digit = int.parse(number[i]);
      if (doubleDigit) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      doubleDigit = !doubleDigit;
    }
    return sum % 10 == 0;
  }

  static String _brand(String number) {
    if (number.startsWith('4')) return 'Visa';
    if (number.startsWith('34') || number.startsWith('37')) return 'AMEX';
    final prefix = int.parse(number.substring(0, 2));
    final extended = int.parse(number.substring(0, 4));
    if ((prefix >= 51 && prefix <= 55) ||
        (extended >= 2221 && extended <= 2720)) {
      return 'Mastercard';
    }
    return 'Unknown';
  }
}
