/// Input rules shared by the auth use cases.
///
/// Each returns `null` when the value is acceptable, or the message to show the
/// user. Lifted out of `AuthController` so login and register cannot drift
/// apart, and so the rules are testable without a widget tree.
class Validators {
  Validators._();

  /// 8–15 digits, no separators — matches what the backend accepts.
  static String? phone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Please enter your phone number.';
    if (!RegExp(r'^[0-9]{8,15}$').hasMatch(trimmed)) {
      return 'Please enter a valid phone number (8-15 digits).';
    }
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Please enter a password.';
    if (value.length < 6) {
      return 'Password must be at least 6 characters long.';
    }
    return null;
  }

  static String? required(String value, String fieldLabel) {
    if (value.trim().isEmpty) return 'Please enter your $fieldLabel.';
    return null;
  }
}
