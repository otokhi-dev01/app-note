import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef StoredIdInformation = ({
  String idNumber,
  String name,
  DateTime? dateOfBirth,
});

/// Encrypted, account-scoped storage for sensitive identity information.
class IdInformationStorage {
  static const _storage = FlutterSecureStorage();

  const IdInformationStorage();

  Future<StoredIdInformation> read(String ownerKey) async {
    final prefix = _prefix(ownerKey);
    final dateRaw = await _storage.read(key: '${prefix}date_of_birth');
    return (
      idNumber: await _storage.read(key: '${prefix}number') ?? '',
      name: await _storage.read(key: '${prefix}name') ?? '',
      dateOfBirth: dateRaw == null ? null : DateTime.tryParse(dateRaw),
    );
  }

  Future<void> save({
    required String ownerKey,
    required String idNumber,
    required String name,
    required DateTime dateOfBirth,
  }) async {
    final prefix = _prefix(ownerKey);
    await Future.wait([
      _storage.write(key: '${prefix}number', value: idNumber),
      _storage.write(key: '${prefix}name', value: name),
      _storage.write(
        key: '${prefix}date_of_birth',
        value: _dateOnly(dateOfBirth),
      ),
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
