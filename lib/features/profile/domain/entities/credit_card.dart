class CreditCard {
  final String id;
  final String cardNumber;
  final String cardholderName;
  final String expiryMonth;
  final String expiryYear;
  final String cvv;
  final String cardBrand;

  const CreditCard({
    required this.id,
    required this.cardNumber,
    required this.cardholderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
    required this.cardBrand,
  });

  String get obscuredNumber {
    if (cardNumber.length < 4) return cardNumber;
    return '•••• •••• •••• ${cardNumber.substring(cardNumber.length - 4)}';
  }

  String get expiryDate => '$expiryMonth/$expiryYear';

  CreditCard copyWith({
    String? id,
    String? cardNumber,
    String? cardholderName,
    String? expiryMonth,
    String? expiryYear,
    String? cvv,
    String? cardBrand,
  }) {
    return CreditCard(
      id: id ?? this.id,
      cardNumber: cardNumber ?? this.cardNumber,
      cardholderName: cardholderName ?? this.cardholderName,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      cvv: cvv ?? this.cvv,
      cardBrand: cardBrand ?? this.cardBrand,
    );
  }
}
