import 'package:Note/features/profile/domain/entities/card_text_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'extracts a card number and explicitly labelled details from both sides',
    () {
      final card = CardTextParser.parse(
        'VISA\n4242 4242 4242 4242\nVALID FROM 01/24\nVALID THRU 08/30\nCARDHOLDER NAME\nJANE DOE\nCVV: 123',
      );
      expect(card, isNotNull);
      expect(card!.cardNumber, '4242424242424242');
      expect(card.expiryMonth, '08');
      expect(card.expiryYear, '2030');
      expect(card.cardholderName, 'JANE DOE');
      expect(card.cvv, '123');
      expect(card.cardBrand, 'Visa');
    },
  );

  test('does not invent unreadable expiry, name or security code', () {
    final card = CardTextParser.parse(
      '4242 4242 4242 4242\n123\nVALID FROM 01/24',
    )!;
    expect(card.expiryMonth, isEmpty);
    expect(card.expiryYear, isEmpty);
    expect(card.cardholderName, isEmpty);
    expect(card.cvv, isEmpty);
  });

  for (final entry in {
    '378282246310005': 'AMEX',
    '5555555555554444': 'Mastercard',
    '6011111111111117': 'Unknown',
  }.entries) {
    test('recognizes ${entry.value} without substituting Visa', () {
      expect(CardTextParser.parse(entry.key)!.cardBrand, entry.value);
    });
  }

  test('rejects OCR mistakes and text with no complete card number', () {
    for (final text in [
      '4242 4242 4242 4241',
      '0000 0000 0000 0000',
      'Expiry 08/30',
      '4242 XXXX XXXX 4242',
    ]) {
      expect(CardTextParser.parse(text), isNull);
    }
  });
}
