abstract final class AuthInputValidator {
  static const int minimumPhoneLength = 8;
  static const int maximumPhoneLength = 55;
  static const int minimumPasswordLength = 6;
  static const int maximumPasswordLength = 100;

  static String normalizePhone(String phone) => phone.trim();

  static String? validatePhone(String phone) {
    final String normalizedPhone = normalizePhone(phone);

    if (normalizedPhone.isEmpty) {
      return 'Please enter your phone number.';
    }

    if (normalizedPhone.length < minimumPhoneLength ||
        normalizedPhone.length > maximumPhoneLength) {
      return 'Phone number must contain between $minimumPhoneLength and '
          '$maximumPhoneLength characters.';
    }

    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Please enter your password.';
    }

    if (password.length < minimumPasswordLength ||
        password.length > maximumPasswordLength) {
      return 'Password must contain between $minimumPasswordLength and '
          '$maximumPasswordLength characters.';
    }

    return null;
  }
}
