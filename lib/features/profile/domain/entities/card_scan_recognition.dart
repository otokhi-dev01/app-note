import 'package:Note/features/profile/domain/entities/card_text_parser.dart';
import 'package:Note/features/profile/domain/entities/credit_card.dart';

/// Combines both sides without mistaking a number on the front for a CVV.
abstract final class CardScanRecognition {
  static String? frontCandidate(String text) =>
      CardTextParser.parse(text)?.cardNumber;

  static String? backCandidate(String text, {bool fourDigitCode = false}) {
    final labelled = RegExp(
      r'\b(?:CVV2?|CVC2?|CID|SECURITY CODE)\s*:?\s*(\d{3,4})\b',
      caseSensitive: false,
    ).firstMatch(text)?[1];
    if (labelled != null) return labelled;
    final candidates = text
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where(
          (line) =>
              RegExp(fourDigitCode ? r'^\d{4}$' : r'^\d{3}$').hasMatch(line),
        )
        .toSet();
    return candidates.length == 1 ? candidates.single : null;
  }

  static CreditCard? parseSides(String front, String back) {
    final card = CardTextParser.parse('$front\n$back');
    if (card == null) return null;
    var name = card.cardholderName;
    if (name.isEmpty) {
      final candidates = front
          .split(RegExp(r'[\r\n]+'))
          .map((line) => line.trim())
          .where(
            (line) => RegExp(
              r"^[A-Z][A-Z.'-]+(?: [A-Z][A-Z.'-]+){1,4}$",
            ).hasMatch(line),
          )
          .where(
            (line) => !RegExp(
              r'\b(BANK|CARD|DEBIT|CREDIT|VALID|THRU|UNTIL|VISA|MASTERCARD|AMERICAN|EXPRESS|SIGNATURE|AUTHORIZED|PLATINUM|WORLD|BUSINESS)\b',
            ).hasMatch(line),
          )
          .toList();
      if (candidates.length == 1) name = candidates.single;
    }
    return card.copyWith(
      cardholderName: name,
      cvv: card.cvv.isNotEmpty
          ? card.cvv
          : backCandidate(back, fourDigitCode: card.cardBrand == 'AMEX') ?? '',
    );
  }
}
