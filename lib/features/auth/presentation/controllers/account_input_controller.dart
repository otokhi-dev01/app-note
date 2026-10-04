import 'package:flutter/material.dart';
import 'package:intl_phone_field/countries.dart';

/// Keeps the editable account separate from the phone value sent to the API.
class AccountInputController extends TextEditingController {
  Country _country = countries.firstWhere((country) => country.code == 'KH');

  bool get isPhoneInput =>
      RegExp(r'^\+?[0-9][0-9\s().-]*$').hasMatch(text.trim());

  /// Country changes only through an explicit picker selection.
  Country get country => _country;

  /// Restores a registered account without repeating the selected dial code
  /// inside the editable phone field. The country comes from explicit metadata,
  /// never from inspecting the number's prefix.
  void setAccount(String account, {String? countryCode}) {
    if (countryCode != null) {
      for (final candidate in countries) {
        if (candidate.code == countryCode) {
          _country = candidate;
          break;
        }
      }
    }
    final input = account.trim();
    final prefix = '+${country.fullCountryCode}';
    final phone = RegExp(r'^\+?[0-9][0-9\s().-]*$').hasMatch(input);
    final number = input.startsWith(prefix)
        ? input.substring(prefix.length).trimLeft()
        : input;
    text = phone && number.isNotEmpty ? number : input;
  }

  String get account {
    final input = text.trim();
    if (!isPhoneInput) return input;
    final digits = input.replaceAll(RegExp(r'\D'), '');
    return input.startsWith('+')
        ? '+$digits'
        : '+${country.fullCountryCode}$digits';
  }

  void selectCountry(Country country) {
    _country = country;
    notifyListeners();
  }
}
