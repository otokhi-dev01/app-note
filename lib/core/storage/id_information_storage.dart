import 'dart:convert';
import 'dart:io';
import 'package:Note/core/storage/app_media_storage.dart';
import 'package:Note/features/profile/domain/entities/national_id_card.dart';
import 'package:Note/features/profile/domain/entities/passport_card.dart';
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

  Future<PassportCard?> readPassport(String ownerKey) async {
    final raw = await _storage.read(key: '${_prefix(ownerKey)}snapshot');
    if (raw != null) {
      final snapshot = Map<String, dynamic>.from(jsonDecode(raw));
      final data = snapshot['passport'] != null
          ? Map<String, dynamic>.from(snapshot['passport'])
          : null;
      if (data == null) return null;
      return PassportCard.fromJson(
        data,
        imagePath: await AppMediaStorage.resolve(data['imagePath']),
      );
    }
    return null;
  }

  Future<List<PassportCard>> readPassports(String ownerKey) async {
    final raw = await _storage.read(key: '${_prefix(ownerKey)}snapshot');
    if (raw != null) {
      final snapshot = Map<String, dynamic>.from(jsonDecode(raw));
      if (snapshot['passports'] is List) {
        return Future.wait(
          (snapshot['passports'] as List).map((entry) async {
            final data = Map<String, dynamic>.from(entry);
            return PassportCard.fromJson(
              data,
              imagePath: await AppMediaStorage.resolve(data['imagePath']),
            );
          }),
        );
      }
    }
    return [];
  }

  Future<void> savePassport({
    required String ownerKey,
    required PassportCard passport,
  }) async {
    final raw = await _storage.read(key: '${_prefix(ownerKey)}snapshot');
    final Map<String, dynamic> snapshot = raw != null
        ? Map<String, dynamic>.from(jsonDecode(raw))
        : {};

    final passports = snapshot['passports'] is List
        ? List<Map<String, dynamic>>.from(snapshot['passports'])
        : <Map<String, dynamic>>[];

    final folder = 'identity_cards/${_prefix(ownerKey)}';
    String? relativePath;
    if (passport.imagePath != null && File(passport.imagePath!).existsSync()) {
      final saved = await AppMediaStorage.persist(
        sourcePath: passport.imagePath!,
        folder: folder,
        fileName: 'passport_${DateTime.now().microsecondsSinceEpoch}',
      );
      relativePath = await AppMediaStorage.makeRelative(saved);
    } else {
      relativePath = passport.imagePath;
    }

    final data = passport.copyWith(imagePath: relativePath).toJson();
    final index = passports.indexWhere(
      (p) => p['passportNumber'] == passport.passportNumber,
    );
    if (index < 0) {
      passports.add(data);
    } else {
      passports[index] = data;
    }

    snapshot['passports'] = passports;
    snapshot['passport'] = data;

    await _storage.write(
      key: '${_prefix(ownerKey)}snapshot',
      value: jsonEncode(snapshot),
    );
  }

  Future<void> deletePassport(String ownerKey, String passportNumber) async {
    final raw = await _storage.read(key: '${_prefix(ownerKey)}snapshot');
    if (raw == null) return;

    final Map<String, dynamic> snapshot = Map<String, dynamic>.from(
      jsonDecode(raw),
    );
    if (snapshot['passports'] is! List) return;

    final passports = List<Map<String, dynamic>>.from(snapshot['passports']);
    final removed = passports
        .where((p) => p['passportNumber'] == passportNumber)
        .toList();
    passports.removeWhere((p) => p['passportNumber'] == passportNumber);

    if (snapshot['passport']?['passportNumber'] == passportNumber) {
      snapshot['passport'] = passports.isNotEmpty ? passports.last : null;
    }
    snapshot['passports'] = passports;

    await _storage.write(
      key: '${_prefix(ownerKey)}snapshot',
      value: jsonEncode(snapshot),
    );

    // Delete image if not referenced anymore
    for (final entry in removed) {
      final path = entry['imagePath'] as String?;
      if (path != null &&
          !passports.any((p) => p['imagePath'] == path) &&
          !(snapshot['cards'] as List? ?? []).any(
            (c) =>
                c['card']?['frontImagePath'] == path ||
                c['card']?['backImagePath'] == path,
          )) {
        await AppMediaStorage.deleteIfManaged(
          path: path,
          folder: 'identity_cards/${_prefix(ownerKey)}',
        );
      }
    }
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

  /// Includes the original single-card snapshot without requiring migration.
  Future<List<Map<String, dynamic>>> _entries(String ownerKey) async {
    final raw = await _storage.read(key: '${_prefix(ownerKey)}snapshot');
    if (raw != null) {
      final snapshot = Map<String, dynamic>.from(jsonDecode(raw));
      if (snapshot['cards'] is List) {
        return (snapshot['cards'] as List)
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
      }
      return [snapshot];
    }
    final legacy = await readCard(ownerKey);
    if (legacy == null) return [];
    final profile = await read(ownerKey);
    return [
      {
        'profile': {
          'idNumber': profile.idNumber,
          'name': profile.name,
          'dateOfBirth': profile.dateOfBirth?.toIso8601String(),
          'placeOfBirth': profile.placeOfBirth,
          'currentAddress': profile.currentAddress,
          'expiryDate': profile.expiryDate?.toIso8601String(),
        },
        'card': legacy.toJson(),
      },
    ];
  }

  Future<List<NationalIdCard>> readCards(String ownerKey) async {
    final entries = await _entries(ownerKey);
    return Future.wait(
      entries.map((entry) async {
        final data = Map<String, dynamic>.from(entry['card']);
        return NationalIdCard.fromJson(
          data,
          frontImagePath: await AppMediaStorage.resolve(data['frontImagePath']),
          backImagePath: await AppMediaStorage.resolve(data['backImagePath']),
        );
      }),
    );
  }

  Future<void> _writeEntries(
    String ownerKey,
    List<Map<String, dynamic>> entries,
    Map<String, dynamic> selected,
  ) async {
    final key = '${_prefix(ownerKey)}snapshot';
    final raw = await _storage.read(key: key);
    final snapshot = raw == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw));
    // Changing the default identity must retain other saved documents.
    await _storage.write(
      key: key,
      value: jsonEncode({
        ...snapshot,
        'profile': selected['profile'],
        'card': selected['card'],
        'cards': entries,
      }),
    );
  }

  Future<void> selectCard(String ownerKey, String idNumber) async {
    final entries = await _entries(ownerKey);
    final selected = entries.firstWhere(
      (entry) => entry['card']['idNumber'] == idNumber,
    );
    await _writeEntries(ownerKey, entries, selected);
  }

  Future<void> deleteCard(String ownerKey, String idNumber) async {
    final entries = await _entries(ownerKey);
    final removed = entries
        .where((entry) => entry['card']['idNumber'] == idNumber)
        .toList();
    entries.removeWhere((entry) => entry['card']['idNumber'] == idNumber);
    if (removed.isEmpty) return;
    if (entries.isEmpty) {
      await delete(ownerKey);
      return;
    }
    final active = await readCard(ownerKey);
    final selected = entries.firstWhere(
      (entry) => entry['card']['idNumber'] == active?.idNumber,
      orElse: () => entries.last,
    );
    await _writeEntries(ownerKey, entries, selected);
    // Only remove images that no remaining card references.
    for (final entry in removed) {
      for (final side in ['frontImagePath', 'backImagePath']) {
        final path = entry['card'][side] as String?;
        if (entries.any(
          (item) =>
              item['card']['frontImagePath'] == path ||
              item['card']['backImagePath'] == path,
        )) {
          continue;
        }
        await AppMediaStorage.deleteIfManaged(
          path: path,
          folder: 'identity_cards/${_prefix(ownerKey)}',
        );
      }
    }
  }

  Future<void> delete(String ownerKey) async {
    final prefix = _prefix(ownerKey);
    await _storage.delete(key: '${prefix}snapshot');
    // Also clean up any legacy pre-snapshot keys if they exist.
    await _storage.delete(key: '${prefix}number');
    await _storage.delete(key: '${prefix}name');
    await _storage.delete(key: '${prefix}date_of_birth');
    await _storage.delete(key: '${prefix}place_of_birth');
    await _storage.delete(key: '${prefix}current_address');
    await _storage.delete(key: '${prefix}expiry_date');

    // Delete managed images.
    final folder = 'identity_cards/$prefix';
    await AppMediaStorage.deleteFolderIfManaged(folder: folder);
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
    final entries = await _entries(ownerKey);
    final cards = await readCards(ownerKey);
    final sameCard = cards
        .where((card) => card.idNumber == idNumber)
        .firstOrNull;
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
        nameKhmer: name == sameCard.nameLatin || name == sameCard.nameKhmer
            ? sameCard.nameKhmer
            : card.nameKhmer,
        nameLatin: name == sameCard.nameLatin || name == sameCard.nameKhmer
            ? sameCard.nameLatin
            : card.nameLatin,
        validityYears: sameCard.validityYears,
        chipIntegrityPercent: sameCard.chipIntegrityPercent,
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
        documentType: sameCard.documentType,
        gender: sameCard.gender,
        nationality: sameCard.nationality,
        issuingCountry: sameCard.issuingCountry,
        issuedDate: sameCard.issuedDate,
        issuingAuthority: sameCard.issuingAuthority,
        additionalFields: sameCard.additionalFields,
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
    final entry = <String, dynamic>{
      'profile': {
        'idNumber': idNumber,
        'name': name,
        'dateOfBirth': dateOfBirth == null ? null : _dateOnly(dateOfBirth),
        'placeOfBirth': card.displayPlaceOfBirth,
        'currentAddress': card.displayCurrentAddress,
        'expiryDate': expiryDate == null ? null : _dateOnly(expiryDate),
      },
      'card': data,
    };
    final index = entries.indexWhere(
      (entry) => entry['card']['idNumber'] == idNumber,
    );
    if (index < 0) {
      entries.add(entry);
    } else {
      entries[index] = entry;
    }
    // Commit the collection and selected profile together, preserving old cards.
    await _writeEntries(ownerKey, entries, entry);
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
