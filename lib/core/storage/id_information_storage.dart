import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef StoredIdInformation = ({
  String idNumber,
  String name,
  DateTime? dateOfBirth,
  String placeOfBirth,
  String currentAddress,
  DateTime? expiryDate,
});

/// Encrypted, account-scoped storage for sensitive identity information.
class IdInformationStorage {
  static const _storage = FlutterSecureStorage();

  const IdInformationStorage();

  Future<StoredIdInformation> read(String ownerKey) async {
    final prefix = _prefix(ownerKey);
    final dateRaw = await _storage.read(key: '${prefix}date_of_birth');
    final expiryRaw = await _storage.read(key: '${prefix}expiry_date');
    return (
      idNumber: await _storage.read(key: '${prefix}number') ?? '',
      name: await _storage.read(key: '${prefix}name') ?? '',
      dateOfBirth: dateRaw == null ? null : DateTime.tryParse(dateRaw),
      placeOfBirth: await _storage.read(key: '${prefix}place_of_birth') ?? '',
      currentAddress:
          await _storage.read(key: '${prefix}current_address') ?? '',
      expiryDate: expiryRaw == null ? null : DateTime.tryParse(expiryRaw),
    );
  }

  Future<void> save({
    required String ownerKey,
    required String idNumber,
    required String name,
    required DateTime dateOfBirth,
    String placeOfBirth = '',
    String currentAddress = '',
    DateTime? expiryDate,
  }) async {
    final prefix = _prefix(ownerKey);
    await Future.wait([
      _storage.write(key: '${prefix}number', value: idNumber),
      _storage.write(key: '${prefix}name', value: name),
      _storage.write(
        key: '${prefix}date_of_birth',
        value: _dateOnly(dateOfBirth),
      ),
      _storage.write(key: '${prefix}place_of_birth', value: placeOfBirth),
      _storage.write(key: '${prefix}current_address', value: currentAddress),
      if (expiryDate != null)
        _storage.write(
          key: '${prefix}expiry_date',
          value: _dateOnly(expiryDate),
        )
      else
        _storage.delete(key: '${prefix}expiry_date'),
    ]);
  }

  String _prefix(String ownerKey) {
    final encoded = base64Url.encode(utf8.encode(ownerKey)).replaceAll('=', '');
    return 'profile_id_${encoded}_';
  }

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
