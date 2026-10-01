import 'package:flutter/material.dart';
import 'package:intl_phone_field/countries.dart';

/// Keeps the editable account separate from the phone value sent to the API.
class AccountInputController extends TextEditingController {
  Country _country = countries.firstWhere((country) => country.code == 'KH');

  bool get isPhoneInput =>
      RegExp(r'^\+?[0-9][0-9\s().-]*$').hasMatch(text.trim());

  Country? get _internationalCountry {
    if (!isPhoneInput || !text.trim().startsWith('+')) return null;
    final digits = text.replaceAll(RegExp(r'\D'), '');
    Country? match;
    for (final country in countries) {
      if (digits.startsWith(country.fullCountryCode) &&
          (match == null ||
              country.fullCountryCode.length > match.fullCountryCode.length ||
              (country.fullCountryCode == match.fullCountryCode &&
                  const ['US', 'GB', 'RU'].contains(country.code)))) {
        match = country;
      }
    }
    if (match?.fullCountryCode == _country.fullCountryCode) return _country;
    return match;
  }

  Country get country => _internationalCountry ?? _country;

  String get account {
    final input = text.trim();
    if (!isPhoneInput) return input;
    final digits = input.replaceAll(RegExp(r'\D'), '');
    return input.startsWith('+')
        ? '+$digits'
        : '+${country.fullCountryCode}$digits';
  }

  void selectCountry(Country country) {
    final previous = _internationalCountry;
    _country = country;
    if (previous != null) {
      final digits = text.replaceAll(RegExp(r'\D'), '');
      final updated =
          '+${country.fullCountryCode}'
          '${digits.substring(previous.fullCountryCode.length)}';
      value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: updated.length),
      );
    } else {
      notifyListeners();
    }
  }
}
