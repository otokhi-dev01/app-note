import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:Note/core/storage/id_information_storage.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/features/profile/domain/entities/national_id_card.dart';
import 'package:Note/features/profile/presentation/widgets/identity_detail_fields.dart';
import 'package:flutter/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final payload = <String, dynamic>{
    'DocumentNumber': '១២៣៤៥៦៧៨៩',
    'FullName': 'សុខ ដារ៉ា',
    'DateOfBirth': '១៥/០៨/១៩៩០',
    'PlaceOfBirth': 'ខេត្តកណ្ដាល',
    'CurrentAddress': 'ភូមិថ្មី\nសង្កាត់ទឹកថ្លា រាជធានីភ្នំពេញ',
    'DocumentType': 'អត្តសញ្ញាណប័ណ្ណ',
    'Gender': 'ស្រី',
    'Nationality': 'ខ្មែរ',
    'issuing_country': 'កម្ពុជា',
    'IssuedDate': '2020-08-15T00:00:00Z',
    'IssuingAuthority': 'ក្រសួងមហាផ្ទៃ',
    'ExpiryDate': '2030-08-15',
    'MrzLines': ['LINE ONE', 'LINE TWO'],
    'registration': {'village': 'ភូមិថ្មី', 'verified': false},
    'otherNames': ['ដារ៉ា', 'DARA'],
    'កំណត់សម្គាល់': 'អាសយដ្ឋានពេញលេញ',
  };

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('km', 'KH');
  });
  tearDown(() => Get.reset());

  test('Parses all document fields without losing Khmer or extra values', () {
    final card = NationalIdCard.fromJson(payload);
    expect(card.idNumber, '១២៣៤៥៦៧៨៩');
    expect(card.nameKhmer, 'សុខ ដារ៉ា');
    expect(card.nameLatin, isEmpty);
    expect(card.placeOfBirthKhmer, 'ខេត្តកណ្ដាល');
    expect(card.placeOfBirthEnglish, isEmpty);
    expect(card.currentAddressKhmer, payload['CurrentAddress']);
    expect(card.currentAddressEnglish, isEmpty);
    expect(card.dateOfBirthAsDate, DateTime(1990, 8, 15));
    expect(card.issuedDateAsDate, DateTime(2020, 8, 15));
    expect(card.expiryDateAsDate, DateTime(2030, 8, 15));
    expect(card.additionalFields.keys, [
      'registration',
      'otherNames',
      'កំណត់សម្គាល់',
    ]);
    expect(NationalIdCard.fromJson(card.toJson()).toJson(), card.toJson());
    final details = identityAdditionalDetails(card);
    expect(details, contains((label: 'ភេទ', value: 'ស្រី')));
    expect(details, contains((label: 'សញ្ជាតិ', value: 'ខ្មែរ')));
    expect(
      details,
      contains((label: 'registration · verified', value: 'false')),
    );
    expect(
      details,
      contains((label: 'កំណត់សម្គាល់', value: 'អាសយដ្ឋានពេញលេញ')),
    );
  });

  test('Storage reload and profile edits retain every API field', () async {
    const storage = IdInformationStorage();
    final card = NationalIdCard.fromJson(payload);
    await storage.save(
      ownerKey: 'id:one',
      idNumber: card.idNumber,
      name: card.nameKhmer,
      dateOfBirth: card.dateOfBirthAsDate,
      scannedCard: card,
    );
    final restored = (await storage.readCard('id:one'))!;
    expect(restored.toJson(), card.toJson());
    await storage.save(
      ownerKey: 'id:one',
      idNumber: card.idNumber,
      name: 'ឈ្មោះថ្មី',
      dateOfBirth: card.dateOfBirthAsDate,
    );
    final edited = (await storage.readCard('id:one'))!;
    expect(edited.nameKhmer, 'ឈ្មោះថ្មី');
    expect(identityAdditionalDetails(edited), identityAdditionalDetails(card));
    expect(await storage.readCard('id:two'), isNull);
  });

  test('Partial rescan retains extra fields only for the same identity', () {
    final previous = NationalIdCard.fromJson(payload);
    final partial = NationalIdCard.fromJson({'idNumber': previous.idNumber});
    final merged = partial.fillMissingFrom(previous);
    expect(
      identityAdditionalDetails(merged),
      identityAdditionalDetails(previous),
    );
    final different = partial
        .copyWith(idNumber: 'other')
        .fillMissingFrom(previous);
    expect(different.additionalFields, isEmpty);
    expect(different.nationality, isEmpty);
  });
}
