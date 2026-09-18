import 'dart:convert';
import 'dart:io';
import 'package:Note/core/storage/app_media_storage.dart';
import 'package:Note/features/profile/domain/entities/national_id_card.dart';
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
    final snapshot = await _storage.read(key: '${_prefix(ownerKey)}snapshot');
    if (snapshot != null) {
      final profile = Map<String, dynamic>.from(
        jsonDecode(snapshot)['profile'],
      );
      return (
        idNumber: profile['idNumber'] as String,
        name: profile['name'] as String,
        dateOfBirth: DateTime.tryParse(profile['dateOfBirth'] ?? ''),
        placeOfBirth: profile['placeOfBirth'] as String,
        currentAddress: profile['currentAddress'] as String,
        expiryDate: DateTime.tryParse(profile['expiryDate'] ?? ''),
      );
    }
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

  Future<NationalIdCard?> readCard(String ownerKey) async {
    final raw = await _storage.read(key: '${_prefix(ownerKey)}snapshot');
    if (raw != null) {
      final data = Map<String, dynamic>.from(jsonDecode(raw)['card']);
      return NationalIdCard.fromJson(
        data,
        frontImagePath: await AppMediaStorage.resolve(data['frontImagePath']),
        backImagePath: await AppMediaStorage.resolve(data['backImagePath']),
      );
    }
    // Restore existing profile-only records created before card persistence.
    final old = await read(ownerKey);
    if (old.idNumber.isEmpty) return null;
    return _fromProfile(
      old.idNumber,
      old.name,
      old.dateOfBirth,
      old.placeOfBirth,
      old.currentAddress,
      old.expiryDate,
    );
  }

  Future<void> save({
    required String ownerKey,
    required String idNumber,
    required String name,
    required DateTime? dateOfBirth,
    String placeOfBirth = '',
    String currentAddress = '',
    DateTime? expiryDate,
    NationalIdCard? scannedCard,
  }) async {
    final previous = await readCard(ownerKey);
    final sameCard = previous?.idNumber == idNumber ? previous : null;
    var card =
        scannedCard ??
        _fromProfile(
          idNumber,
          name,
          dateOfBirth,
          placeOfBirth,
          currentAddress,
          expiryDate,
        );
    if (scannedCard == null && sameCard != null) {
      // Preserve the separate scripts when a profile edit leaves a field alone.
      card = card.copyWith(
        nameKhmer: sameCard.nameKhmer,
        placeOfBirthKhmer: placeOfBirth == sameCard.displayPlaceOfBirth
            ? sameCard.placeOfBirthKhmer
            : card.placeOfBirthKhmer,
        placeOfBirthEnglish: placeOfBirth == sameCard.displayPlaceOfBirth
            ? sameCard.placeOfBirthEnglish
            : card.placeOfBirthEnglish,
        currentAddressKhmer: currentAddress == sameCard.displayCurrentAddress
            ? sameCard.currentAddressKhmer
            : card.currentAddressKhmer,
        currentAddressEnglish: currentAddress == sameCard.displayCurrentAddress
            ? sameCard.currentAddressEnglish
            : card.currentAddressEnglish,
        mrzLines: sameCard.mrzLines,
        frontImagePath: sameCard.frontImagePath,
        backImagePath: sameCard.backImagePath,
      );
    }
    final folder = 'identity_cards/${_prefix(ownerKey)}';
    Future<String?> persist(String? path, String side) async {
      if (path == null || !File(path).existsSync()) return null;
      final saved = await AppMediaStorage.persist(
        sourcePath: path,
        folder: folder,
        fileName: '${side}_${DateTime.now().microsecondsSinceEpoch}',
      );
      return AppMediaStorage.makeRelative(saved);
    }

    final data = card.toJson();
    data['frontImagePath'] = await persist(card.frontImagePath, 'front');
    data['backImagePath'] = await persist(card.backImagePath, 'back');
    // A single encrypted write commits both screens together.
    await _storage.write(
      key: '${_prefix(ownerKey)}snapshot',
      value: jsonEncode({
        'profile': {
          'idNumber': idNumber,
          'name': name,
          'dateOfBirth': dateOfBirth == null ? null : _dateOnly(dateOfBirth),
          'placeOfBirth': card.displayPlaceOfBirth,
          'currentAddress': card.displayCurrentAddress,
          'expiryDate': expiryDate == null ? null : _dateOnly(expiryDate),
        },
        'card': data,
      }),
    );
  }

  NationalIdCard _fromProfile(
    String number,
    String name,
    DateTime? dob,
    String birthPlace,
    String address,
    DateTime? expiry,
  ) {
    bool khmer(String text) => RegExp(r'[\u1780-\u17FF]').hasMatch(text);
    String displayDate(DateTime? date) => date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    return NationalIdCard(
      idNumber: number,
      nameKhmer: khmer(name) ? name : '',
      nameLatin: khmer(name) ? '' : name,
      dateOfBirth: displayDate(dob),
      placeOfBirthKhmer: khmer(birthPlace) ? birthPlace : '',
      placeOfBirthEnglish: khmer(birthPlace) ? '' : birthPlace,
      currentAddressKhmer: khmer(address) ? address : '',
      currentAddressEnglish: khmer(address) ? '' : address,
      expiryDate: displayDate(expiry),
      mrzLines: const [],
    );
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
