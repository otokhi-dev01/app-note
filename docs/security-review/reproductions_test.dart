import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:Note/core/error/failures.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/storage/profile_extras_storage.dart';
import 'package:Note/core/storage/id_information_storage.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/core/utils/attachment_url.dart';
import 'package:Note/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';
import 'package:Note/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:Note/features/folder/data/repositories/folder_sync_repository.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/folder/domain/repositories/folder_repository.dart';
import 'package:Note/features/note/data/repositories/note_sync_repository.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/domain/entities/note_bundle.dart';
import 'package:Note/features/note/domain/repositories/note_repository.dart';
import 'package:Note/features/profile/domain/entities/passport_card.dart';

class FolderFake implements FolderRepository {
  @override
  Future<Result<FolderBundle>> getFolders() async => const Ok(FolderBundle());
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('$invocation');
}

class NoteFake implements NoteRepository {
  Future<Result<NoteBundle>> Function()? onGet;
  Future<Result<int>> Function(String)? onSave;
  @override
  Future<Result<NoteBundle>> getNotes({int? folderId}) => onGet!();
  @override
  Future<Result<int>> saveNoteMetadata({
    required int folderId,
    required String title,
    int noteId = 0,
  }) => onSave!(title);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('$invocation');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SessionStorage session;
  late NoteFake remote;
  late NoteSyncRepository notes;
  late Directory temporary;
  setUpAll(() async {
    temporary = await Directory.systemTemp.createTemp(
      'app_note_security_review_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => temporary.path,
        );
    await GetStorage.init();
  });
  tearDownAll(() async => temporary.delete(recursive: true));
  setUp(() async {
    Get.testMode = true;
    await GetStorage().erase();
    // This isolated test lives under docs to avoid joining the normal suite.
    // ignore: invalid_use_of_visible_for_testing_member
    FlutterSecureStorage.setMockInitialValues({});
    session = Get.put(SessionStorage());
    await session.ready;
    session.token.value = 'synthetic-token-A';
    session.user.value = const UserData(id: 'A');
    remote = NoteFake();
    notes = NoteSyncRepository(
      remote,
      session,
      FolderSyncRepository(FolderFake(), session),
    );
  });
  tearDown(() => Get.reset());

  test(
    'CONFIRMED: external attachment URL receives the synthetic bearer header',
    () {
      expect(
        normalizeAttachmentUrl('https://outside.example/private.jpg'),
        'https://outside.example/private.jpg',
      );
      expect(attachmentAuthHeaders(), {
        'Authorization': 'Bearer synthetic-token-A',
      });
      // Image.network passes these two outputs together in production.
    },
  );

  test(
    'CONFIRMED: late account A note response is written to account B cache',
    () async {
      final started = Completer<void>();
      final pending = Completer<Result<NoteBundle>>();
      remote.onGet = () {
        started.complete();
        return pending.future;
      };
      final operation = notes.getNotes();
      await started.future;
      await session.saveSession('synthetic-token-B', const UserData(id: 'B'));
      pending.complete(
        const Ok(
          NoteBundle(
            notes: [
              Note(
                id: 42,
                folderId: 1,
                folderName: 'Notes',
                title: 'Account A private note',
              ),
            ],
          ),
        ),
      );
      await operation;
      final cached = GetStorage().read<List>('account_notes_cache_B')!;
      expect((cached.single as Map)['title'], 'Account A private note');
      expect(GetStorage().read('account_notes_cache_A'), isNull);
    },
  );

  test(
    'CONFIRMED: late account A save queues private content for account B',
    () async {
      final started = Completer<void>();
      final pending = Completer<Result<int>>();
      remote.onSave = (_) {
        started.complete();
        return pending.future;
      };
      final operation = notes.saveNoteMetadata(
        folderId: 1,
        title: 'Account A secret',
      );
      await started.future;
      await session.saveSession('synthetic-token-B', const UserData(id: 'B'));
      pending.complete(const Err(NetworkFailure()));
      await operation;
      final queue = GetStorage().read<List>('account_notes_queue_B')!;
      expect((queue.single as Map)['title'], 'Account A secret');
    },
  );

  test(
    'CONFIRMED: unknown-owner cache is exposed to a new signed-in account',
    () async {
      await GetStorage().write('account_notes_cache_unknown', [
        {
          'id': 7,
          'folderId': 1,
          'title': 'Previous unknown owner private note',
        },
      ]);
      remote.onGet = () async => const Err(NetworkFailure());
      final result = await notes.getNotes();
      expect(
        result.valueOrNull!.notes.single.title,
        'Previous unknown owner private note',
      );
    },
  );

  test('CONFIRMED: shared profile extras survive changing accounts', () async {
    ProfileExtrasStorage().phone = 'synthetic-private-phone-A';
    ProfileExtrasStorage().motherName = 'synthetic-family-name-A';
    await session.saveSession('synthetic-token-B', const UserData(id: 'B'));
    expect(ProfileExtrasStorage().phone, 'synthetic-private-phone-A');
    expect(ProfileExtrasStorage().motherName, 'synthetic-family-name-A');
  });

  test(
    'CONFIRMED: concurrent edit is removed from queue when an older flush completes',
    () async {
      remote.onSave = (_) async => const Err(NetworkFailure());
      await notes.saveNoteMetadata(folderId: 1, title: 'First offline note');
      expect(notes.pendingCount, 1);
      final started = Completer<void>();
      final pending = Completer<Result<int>>();
      remote.onSave = (title) {
        if (title == 'First offline note') {
          started.complete();
          return pending.future;
        }
        return Future.value(const Err(NetworkFailure()));
      };
      final flush = notes.flushPending();
      await started.future;
      await notes.saveNoteMetadata(folderId: 1, title: 'New edit during flush');
      expect(notes.pendingCount, 2);
      pending.complete(const Ok(100));
      await flush;
      expect(notes.pendingCount, 0);
      final cache = GetStorage().read<List>('account_notes_cache_A')!;
      expect(
        cache.any((n) => (n as Map)['title'] == 'New edit during flush'),
        isFalse,
      );
    },
  );

  test(
    'CONFIRMED: account deletion reports success for HTTP 200 success:false',
    () async {
      final api = Get.put(ApiClient());
      api.dio.interceptors.add(
        dio.InterceptorsWrapper(
          onRequest: (request, handler) {
            handler.resolve(
              dio.Response(
                requestOptions: request,
                statusCode: 200,
                data: {'success': false, 'message': 'Account was not deleted'},
              ),
            );
          },
        ),
      );
      await const FlutterSecureStorage().write(
        key: 'profile_id_A_snapshot',
        value: 'synthetic-retained-identity',
      );
      await GetStorage().write('account_notes_cache_A', [
        {'title': 'synthetic-retained-note'},
      ]);
      final result = await AuthRepositoryImpl(
        AuthRemoteDataSource(),
        session,
      ).deleteAccount(password: 'synthetic-password');
      expect(result.isOk, isTrue);
      expect(session.isLoggedIn, isFalse);
      expect(
        await const FlutterSecureStorage().read(key: 'profile_id_A_snapshot'),
        'synthetic-retained-identity',
      );
      expect(GetStorage().read('account_notes_cache_A'), isNotNull);
    },
  );

  const passport = PassportCard(
    passportNumber: 'SYNTHETIC-PASSPORT',
    fullName: 'Synthetic Name',
    dateOfBirth: '',
    gender: '',
    nationality: '',
    expiryDate: '',
    mrzLines: [],
  );

  test(
    'CONFIRMED: saving a passport first makes identity reads throw',
    () async {
      const storage = IdInformationStorage();
      await storage.savePassport(ownerKey: 'A', passport: passport);
      expect(
        (await storage.readPassports('A')).single.passportNumber,
        passport.passportNumber,
      );
      await expectLater(storage.read('A'), throwsA(isA<TypeError>()));
      await expectLater(storage.readCards('A'), throwsA(isA<TypeError>()));
    },
  );

  test(
    'CONFIRMED: deleting the last ID card also deletes saved passports',
    () async {
      const storage = IdInformationStorage();
      await storage.save(
        ownerKey: 'A',
        idNumber: 'SYNTHETIC-ID',
        name: 'Synthetic Name',
        dateOfBirth: null,
      );
      await storage.savePassport(ownerKey: 'A', passport: passport);
      expect(await storage.readPassports('A'), hasLength(1));
      await storage.deleteCard('A', 'SYNTHETIC-ID');
      expect(await storage.readPassports('A'), isEmpty);
    },
  );
}
