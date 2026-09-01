import 'package:get/get.dart';
class Validators {
  Validators._();

  static String? phone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'validator_phone_required'.tr;
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(trimmed)) {
      return 'validator_phone_invalid'.tr;
    }
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'validator_password_required'.tr;
    if (value.length < 6) {
      return 'validator_password_too_short'.tr;
    }
    return null;
  }

  static String? required(String value, String fieldLabel) {
    if (value.trim().isEmpty) return 'Please enter your $fieldLabel.';
    return null;
  }
}
