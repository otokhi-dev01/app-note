import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:Note/core/error/failures.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';
import 'package:Note/features/profile/data/datasources/identity_remote_data_source.dart';
import 'package:Note/features/profile/data/repositories/identity_repository_impl.dart';
import 'package:Note/features/profile/domain/entities/identity_document.dart';
import 'package:Note/features/profile/domain/entities/national_id_card.dart';
import 'package:Note/features/profile/domain/usecases/identity_usecases.dart';
import 'package:Note/features/profile/presentation/views/document_upload_view.dart';

class _Session extends SessionStorage {
  @override
  Future<void> loadSession() async {}
  @override
  Future<void> saveSession(
    String newToken,
    UserData userData, {
    String? refreshToken,
  }) async {
    token.value = newToken;
    this.refreshToken.value = refreshToken;
    user.value = userData;
  }
}

class _Adapter implements dio.HttpClientAdapter {
  final requests = <dio.RequestOptions>[];
  final bodies = <String>[];
  FutureOr<dio.ResponseBody> Function(dio.RequestOptions) respond = (_) =>
      _json({'Success': true});

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }
    bodies.add(utf8.decode(bytes, allowMalformed: true));
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

dio.ResponseBody _json(Object? body, [int status = 200]) =>
    dio.ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        dio.Headers.contentTypeHeader: ['application/json'],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Session session;
  late _Adapter adapter;
  late UploadIdentityDocument upload;
  late Directory directory;
  late String frontPath;
  late String backPath;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('document_upload_test_');
    frontPath = '${directory.path}/front.jpg';
    backPath = '${directory.path}/back.png';
    await File(frontPath).writeAsString('front-image-bytes');
    await File(backPath).writeAsString('back-image-bytes');
  });
  tearDownAll(() => directory.delete(recursive: true));

  Future<void> initialize() async {
    Get.testMode = true;
    session = _Session();
    Get.put<SessionStorage>(session);
    await session.ready;
    session.token.value = 'signed-in-token';
    session.refreshToken.value = 'saved-refresh-token';
    final api = Get.put(ApiClient());
    adapter = _Adapter();
    api.dio.httpClientAdapter = adapter;
    upload = Get.put(
      UploadIdentityDocument(
        IdentityRepositoryImpl(IdentityRemoteDataSource(api: api)),
      ),
    );
  }

  setUp(initialize);
  tearDown(() => Get.reset());

  test(
    'Identity API unwraps Khmer details and preserves additional fields',
    () async {
      adapter.respond = (_) => _json({
        'Data': {
          'DocumentNumber': '123',
          'FullName': 'សុខ ដារ៉ា',
          'Gender': 'ស្រី',
          'Nationality': 'ខ្មែរ',
          'IssuedDate': '2024-01-02',
          'IssuingAuthority': 'ក្រសួងមហាផ្ទៃ',
          'village': 'ភូមិថ្មី',
        },
      });
      final card = await IdentityRemoteDataSource(
        api: Get.find<ApiClient>(),
      ).scanNationalId(frontImagePath: frontPath, backImagePath: backPath);
      expect(card.nameKhmer, 'សុខ ដារ៉ា');
      expect(card.gender, 'ស្រី');
      expect(card.nationality, 'ខ្មែរ');
      expect(card.issuedDate, '02-01-2024');
      expect(card.issuingAuthority, 'ក្រសួងមហាផ្ទៃ');
      expect(card.additionalFields, {'village': 'ភូមិថ្មី'});
      expect(card.frontImagePath, frontPath);
      expect(card.backImagePath, backPath);
    },
  );

  test(
    'Uploads exact multipart fields and both image files to the account server',
    () async {
      final document = IdentityDocument(
        documentType: ' National ID ',
        documentNumber: ' ABC123 ',
        fullName: ' Example User ',
        dateOfBirth: DateTime(1990, 2, 3),
        gender: 'F',
        nationality: 'Cambodian',
        issuingCountry: 'Cambodia',
        issuedDate: DateTime(2020, 1, 2),
        expiryDate: DateTime(2030, 1, 2),
        issuingAuthority: 'Example Authority',
        frontImagePath: frontPath,
        backImagePath: backPath,
      );
      expect((await upload(document)).isOk, isTrue);
      final request = adapter.requests.single;
      expect(
        request.uri.toString(),
        'https://chat.piisiit.com/upload-document',
      );
      expect(request.method, 'POST');
      expect(request.headers['Authorization'], 'Bearer signed-in-token');
      expect(request.contentType, startsWith('multipart/form-data'));
      final data = request.data as dio.FormData;
      expect(Map.fromEntries(data.fields), {
        'DocumentType': 'National ID',
        'DocumentNumber': 'ABC123',
        'FullName': 'Example User',
        'DateOfBirth': '1990-02-03T00:00:00.000',
        'Gender': 'F',
        'Nationality': 'Cambodian',
        'IssuingCountry': 'Cambodia',
        'IssuedDate': '2020-01-02T00:00:00.000',
        'ExpiryDate': '2030-01-02T00:00:00.000',
        'IssuingAuthority': 'Example Authority',
      });
      expect(data.files.map((entry) => entry.key), ['FrontImage', 'BackImage']);
      expect(data.files.first.value.filename, 'front.jpg');
      expect(data.files.first.value.contentType.toString(), 'image/jpeg');
      expect(data.files.last.value.contentType.toString(), 'image/png');
      expect(adapter.bodies.single, contains('front-image-bytes'));
      expect(adapter.bodies.single, contains('back-image-bytes'));
      expect(File(frontPath).existsSync(), isTrue);
    },
  );

  test(
    'Requires document type/number, omits optional fields, and prevents guest upload',
    () async {
      expect(
        (await upload(
          const IdentityDocument(documentType: '', documentNumber: '123'),
        )).failureOrNull,
        isA<ValidationFailure>(),
      );
      expect(
        (await upload(
          const IdentityDocument(documentType: 'Passport', documentNumber: ' '),
        )).isErr,
        isTrue,
      );
      expect(
        (await upload(
          IdentityDocument(
            documentType: 'ID',
            documentNumber: '123',
            issuedDate: DateTime(2030),
            expiryDate: DateTime(2020),
          ),
        )).isErr,
        isTrue,
      );
      expect(adapter.requests, isEmpty);
      const document = IdentityDocument(
        documentType: 'Passport',
        documentNumber: '123',
      );
      expect((await upload(document)).isOk, isTrue);
      final form = adapter.requests.single.data as dio.FormData;
      expect(Map.fromEntries(form.fields), {
        'DocumentType': 'Passport',
        'DocumentNumber': '123',
      });
      expect(form.files, isEmpty);
      session.token.value = null;
      expect(
        (await upload(document)).failureOrNull,
        isA<UnauthorizedFailure>(),
      );
      expect(adapter.requests, hasLength(1));
    },
  );

  test(
    'Server failure, malformed success and missing files are not successful uploads',
    () async {
      const document = IdentityDocument(
        documentType: 'ID',
        documentNumber: '123',
      );
      for (final body in [
        {'success': false, 'message': 'Rejected'},
        {'data': {}},
        '<html>proxy error</html>',
      ]) {
        adapter.respond = (_) => _json(body);
        expect((await upload(document)).isErr, isTrue);
      }
      adapter.respond = (_) =>
          _json({'Success': false, 'Message': 'Try later'}, 429);
      expect((await upload(document)).failureOrNull?.message, 'Try later');
      final count = adapter.requests.length;
      final missing = await upload(
        IdentityDocument(
          documentType: 'ID',
          documentNumber: '123',
          frontImagePath: '${directory.path}/missing.jpg',
        ),
      );
      expect(missing.failureOrNull?.message, contains('could not be read'));
      expect(adapter.requests, hasLength(count));
      adapter.respond = (request) => throw dio.DioException(
        requestOptions: request,
        type: dio.DioExceptionType.receiveTimeout,
      );
      expect((await upload(document)).failureOrNull, isA<NetworkFailure>());
    },
  );

  test(
    'Session refresh retries with a fresh multipart body containing the image bytes',
    () async {
      var attempts = 0;
      adapter.respond = (request) {
        if (request.uri.path.endsWith('/refresh-token')) {
          return _json({
            'success': true,
            'data': {'token': 'refreshed-token'},
          });
        }
        attempts++;
        return attempts == 1
            ? _json({'message': 'Expired'}, 401)
            : _json({'success': true});
      };
      expect(
        (await upload(
          IdentityDocument(
            documentType: 'ID',
            documentNumber: '123',
            frontImagePath: frontPath,
          ),
        )).isOk,
        isTrue,
      );
      expect(attempts, 2);
      expect(adapter.requests, hasLength(3));
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer refreshed-token',
      );
      expect(adapter.bodies.first, contains('front-image-bytes'));
      expect(adapter.bodies.last, contains('front-image-bytes'));
      expect(
        identical(adapter.requests.first.data, adapter.requests.last.data),
        isFalse,
      );
    },
  );

  testWidgets('Upload review prefills all returned identity document fields', (
    tester,
  ) async {
    final card = NationalIdCard.fromJson({
      'DocumentNumber': '123',
      'FullName': 'សុខ ដារ៉ា',
      'DocumentType': 'អត្តសញ្ញាណប័ណ្ណ',
      'Gender': 'ស្រី',
      'Nationality': 'ខ្មែរ',
      'IssuingCountry': 'កម្ពុជា',
      'IssuedDate': '2024-01-02',
      'IssuingAuthority': 'ក្រសួងមហាផ្ទៃ',
    });
    await tester.pumpWidget(
      GetMaterialApp(home: DocumentUploadView(initialCard: card)),
    );
    for (final entry in {
      'FullName': 'សុខ ដារ៉ា',
      'DocumentType': 'អត្តសញ្ញាណប័ណ្ណ',
      'Gender': 'ស្រី',
      'Nationality': 'ខ្មែរ',
      'IssuingCountry': 'កម្ពុជា',
      'IssuedDate': '2024-01-02',
      'IssuingAuthority': 'ក្រសួងមហាផ្ទៃ',
    }.entries) {
      final field = find.byKey(ValueKey(entry.key));
      expect(tester.widget<TextFormField>(field).controller!.text, entry.value);
    }
  });

  testWidgets(
    'Upload form validates input, retains server failures, and returns only on success',
    (tester) async {
      // Create startup Futures in the widget test's simulated clock.
      Get.reset();
      await initialize();
      IdentityDocument? uploaded;
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  uploaded = await Navigator.of(context).push<IdentityDocument>(
                    MaterialPageRoute(
                      builder: (_) => const DocumentUploadView(),
                    ),
                  );
                },
                child: const Text('Open upload'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open upload'));
      await tester.pumpAndSettle();
      Future<void> submit() async {
        await tester.ensureVisible(find.byType(FilledButton));
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
      }

      await submit();
      expect(adapter.requests, isEmpty);
      expect(find.text('This field is required.'), findsNWidgets(2));
      Future<void> enter(String key, String value) async {
        await tester.ensureVisible(find.byKey(ValueKey(key)));
        await tester.enterText(find.byKey(ValueKey(key)), value);
      }

      await enter('DocumentType', 'Passport');
      await enter('DocumentNumber', 'ABC123');
      await enter('DateOfBirth', '2020-02-31');
      await submit();
      expect(adapter.requests, isEmpty);
      expect(find.text('Enter a valid date as YYYY-MM-DD.'), findsOneWidget);
      await enter('DateOfBirth', '1990-02-03');
      adapter.respond = (_) =>
          _json({'success': false, 'message': 'Document rejected'}, 400);
      await submit();
      expect(find.text('Document rejected'), findsOneWidget);
      expect(uploaded, isNull);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('DocumentNumber')))
            .controller!
            .text,
        'ABC123',
      );
      adapter.respond = (_) => _json({'success': true});
      await submit();
      expect(uploaded?.documentNumber, 'ABC123');
      expect(uploaded?.dateOfBirth, DateTime(1990, 2, 3));
      expect(find.text('Open upload'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
