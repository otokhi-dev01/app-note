import 'dart:async';
import 'dart:convert';
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
  Future<Result<FolderBundle>> Function()? onGet;
  Future<Result<int>> Function()? onSave;
  @override
  Future<Result<FolderBundle>> getFolders() async =>
      onGet == null ? const Ok(FolderBundle()) : await onGet!();
  @override
  Future<Result<int>> saveFolder({
    required int id,
    int? parentId,
    required String name,
    required String iconName,
    required String colorValue,
    int sortOrder = 0,
  }) async => onSave == null ? const Ok(1) : await onSave!();
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
  late FolderFake folderRemote;
  late FolderSyncRepository folders;
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
  tearDownAll(() async {
    await GetStorage().erase();
    await temporary.delete(recursive: true);
  });
  setUp(() async {
    Get.testMode = true;
    await GetStorage().erase();
    FlutterSecureStorage.setMockInitialValues({});
    session = Get.put(SessionStorage());
    await session.ready;
    session.token.value = 'synthetic-token-A';
    session.user.value = const UserData(id: 'A');
    remote = NoteFake();
    folderRemote = FolderFake();
    folders = FolderSyncRepository(folderRemote, session);
    notes = NoteSyncRepository(remote, session, folders);
  });
  tearDown(() => Get.reset());

  test('Late folder responses cannot populate another account cache', () async {
    final started = Completer<void>();
    final result = Completer<Result<FolderBundle>>();
    folderRemote.onGet = () {
      started.complete();
      return result.future;
    };
    final request = folders.getFolders();
    await started.future;
    await session.saveSession('synthetic-token-B', const UserData(id: 'B'));
    result.complete(const Ok(FolderBundle()));
    expect((await request).isErr, isTrue);
    expect(GetStorage().read('account_folders_cache_B'), isNull);
  });

  test(
    'Authorization failures never become successful offline saves',
    () async {
      remote.onSave = (_) async => const Err(UnauthorizedFailure());
      expect(
        (await notes.saveNoteMetadata(folderId: 1, title: 'Denied')).isErr,
        isTrue,
      );
      expect(notes.pendingCount, 0);
      folderRemote.onSave = () async => const Err(UnauthorizedFailure());
      expect(
        (await folders.saveFolder(
          id: 0,
          name: 'Denied',
          iconName: 'folder',
          colorValue: 'blue',
        )).isErr,
        isTrue,
      );
      expect(folders.pendingCount, 0);
    },
  );

  test('Confirmed account deletion removes only that account data', () async {
    final api = Get.put(ApiClient());
    api.dio.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (request, handler) {
          handler.resolve(
            dio.Response(
              requestOptions: request,
              statusCode: 200,
              data: {'success': true},
            ),
          );
        },
      ),
    );
    await GetStorage().write('account_notes_cache_A', [
      {'title': 'A'},
    ]);
    await GetStorage().write('account_notes_cache_B_A', [
      {'title': 'Other'},
    ]);
    await GetStorage().write('guest_notes', [
      {'title': 'Guest'},
    ]);
    ProfileExtrasStorage().phone = 'Private A';
    await const IdInformationStorage().save(
      ownerKey: 'id:A',
      idNumber: 'A-ID',
      name: 'A',
      dateOfBirth: null,
    );
    final result = await AuthRepositoryImpl(
      AuthRemoteDataSource(),
      session,
    ).deleteAccount(password: 'synthetic-password');
    expect(result.isOk, isTrue);
    expect(session.isLoggedIn, isFalse);
    expect(GetStorage().read('account_notes_cache_A'), isNull);
    expect(GetStorage().read('account_notes_cache_B_A'), isNotNull);
    expect(GetStorage().read('guest_notes'), isNotNull);
    expect(await const IdInformationStorage().readCards('id:A'), isEmpty);
    await session.saveSession('synthetic-token-A', const UserData(id: 'A'));
    expect(ProfileExtrasStorage().phone, isEmpty);
  });

  test('Only the note API origin receives attachment credentials', () {
    expect(
      normalizeAttachmentUrl('https://outside.example/private.jpg'),
      'https://outside.example/private.jpg',
    );
    expect(
      attachmentAuthHeaders('https://outside.example/private.jpg'),
      isNull,
    );
    expect(attachmentAuthHeaders('${ApiClient.baseUrl}/attachment/1'), {
      'Authorization': 'Bearer synthetic-token-A',
    });
    // Image.network passes these two outputs together in production.
  });

  test('Late note responses cannot populate another account cache', () async {
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
    expect((await operation).isErr, isTrue);
    expect(GetStorage().read('account_notes_cache_B'), isNull);
    expect(GetStorage().read('account_notes_cache_A'), isNull);
  });

  test('Late failed saves cannot queue another account content', () async {
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
    expect((await operation).isErr, isTrue);
    expect(GetStorage().read('account_notes_queue_B'), isNull);
  });

  test('Unknown-owner cache is not adopted by signed-in accounts', () async {
    await GetStorage().write('account_notes_cache_unknown', [
      {'id': 7, 'folderId': 1, 'title': 'Previous unknown owner private note'},
    ]);
    remote.onGet = () async => const Err(NetworkFailure());
    final result = await notes.getNotes();
    expect(result.valueOrNull!.notes, isEmpty);
  });

  test('Profile extras belong to their originating account', () async {
    ProfileExtrasStorage().phone = 'synthetic-private-phone-A';
    ProfileExtrasStorage().motherName = 'synthetic-family-name-A';
    await session.saveSession('synthetic-token-B', const UserData(id: 'B'));
    expect(ProfileExtrasStorage().phone, isEmpty);
    expect(ProfileExtrasStorage().motherName, isEmpty);
    await session.saveSession('synthetic-token-A', const UserData(id: 'A'));
    expect(ProfileExtrasStorage().phone, 'synthetic-private-phone-A');
    expect(ProfileExtrasStorage().motherName, 'synthetic-family-name-A');
  });

  test('Concurrent edits survive an older queue flush', () async {
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
    final edit = notes.saveNoteMetadata(
      folderId: 1,
      title: 'New edit during flush',
    );
    pending.complete(const Ok(100));
    await flush;
    expect((await edit).isOk, isTrue);
    expect(notes.pendingCount, 1);
    final cache = GetStorage().read<List>('account_notes_cache_A')!;
    expect(
      cache.any((n) => (n as Map)['title'] == 'New edit during flush'),
      isTrue,
    );
  });

  test(
    'Rejected account deletion preserves the session and local data',
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
      expect(result.isErr, isTrue);
      expect(session.isLoggedIn, isTrue);
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
    'Passport-first storage leaves identity reads empty and usable',
    () async {
      const storage = IdInformationStorage();
      await storage.savePassport(ownerKey: 'A', passport: passport);
      expect(
        (await storage.readPassports('A')).single.passportNumber,
        passport.passportNumber,
      );
      expect((await storage.read('A')).idNumber, isEmpty);
      expect(await storage.readCards('A'), isEmpty);
      await storage.save(
        ownerKey: 'A',
        idNumber: 'ID-A',
        name: 'Name',
        dateOfBirth: null,
      );
      expect(await storage.readCards('A'), hasLength(1));
      expect(await storage.readPassports('A'), hasLength(1));
    },
  );

  test('Deleting the last ID card retains saved passports', () async {
    const storage = IdInformationStorage();
    // A migrated installation can still have keys from the old schema.
    final owner = base64Url.encode(utf8.encode('A')).replaceAll('=', '');
    await const FlutterSecureStorage().write(
      key: 'profile_id_${owner}_number',
      value: 'SYNTHETIC-ID',
    );
    await storage.save(
      ownerKey: 'A',
      idNumber: 'SYNTHETIC-ID',
      name: 'Synthetic Name',
      dateOfBirth: null,
    );
    await storage.savePassport(ownerKey: 'A', passport: passport);
    expect(await storage.readPassports('A'), hasLength(1));
    await storage.deleteCard('A', 'SYNTHETIC-ID');
    expect(await storage.readPassports('A'), hasLength(1));
    expect(await storage.readCards('A'), isEmpty);
    expect((await storage.read('A')).idNumber, isEmpty);
    expect(await storage.readCard('A'), isNull);
  });
}
