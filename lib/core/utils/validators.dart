import 'package:get/get.dart';

class Validators {
  Validators._();

  static String? username(String value) {
    final name = value.trim();
    if (name.isEmpty) return 'register_username_required'.tr;
    if (!RegExp(r'^[\p{L}\p{M}\p{N} ]+$', unicode: true).hasMatch(name) ||
        !RegExp(r'\p{L}', unicode: true).hasMatch(name)) {
      return 'register_username_invalid'.tr;
    }
    return null;
  }

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
