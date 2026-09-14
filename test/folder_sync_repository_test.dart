import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import 'package:Note/core/error/failures.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';
import 'package:Note/features/folder/data/repositories/folder_sync_repository.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/folder/domain/repositories/folder_repository.dart';

/// A tiny in-memory stand-in for the real backend. Toggling [online] lets a
/// test simulate connectivity dropping and returning without touching Dio at
/// all — `FolderSyncRepository` only cares about the [NetworkFailure] shape,
/// not how it was produced.
class _FakeFolderRepository implements FolderRepository {
  bool online = true;
  Err<int>? nextSaveRejection;
  int _nextId = 100;
  final Map<int, Folder> byId = {};
  final List<String> calls = [];

  @override
  Future<Result<FolderBundle>> getFolders() async {
    calls.add('getFolders');
    if (!online) return const Err(NetworkFailure());
    final all = byId.values.toList();
    return Ok(
      FolderBundle(
        folders: all.where((f) => !f.isDeleted).toList(),
        trash: all.where((f) => f.isDeleted).toList(),
      ),
    );
  }

  @override
  Future<Result<int>> saveFolder({
    required int id,
    int? parentId,
    required String name,
    required String iconName,
    required String colorValue,
    int sortOrder = 0,
  }) async {
    calls.add('saveFolder:$id');
    if (!online) return const Err(NetworkFailure());
    if (nextSaveRejection != null) {
      final rejection = nextSaveRejection!;
      nextSaveRejection = null;
      return rejection;
    }
    final targetId = id == 0 ? _nextId++ : id;
    final existing = byId[targetId];
    byId[targetId] = Folder(
      id: targetId,
      parentId: parentId,
      name: name,
      iconName: iconName,
      colorValue: colorValue,
      sortOrder: sortOrder,
      noteCount: existing?.noteCount ?? 0,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      deletedAt: existing?.deletedAt,
    );
    return Ok(targetId);
  }

  @override
  Future<Result<void>> deleteRestoreFolder(int folderId, bool isDelete) async {
    calls.add('deleteRestoreFolder:$folderId');
    if (!online) return const Err(NetworkFailure());
    final existing = byId[folderId];
    if (existing == null) return const Err(ServerFailure('Folder not found.'));
    byId[folderId] = Folder(
      id: existing.id,
      parentId: existing.parentId,
      name: existing.name,
      iconName: existing.iconName,
      colorValue: existing.colorValue,
      sortOrder: existing.sortOrder,
      noteCount: existing.noteCount,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      deletedAt: isDelete ? DateTime.now() : null,
    );
    return okVoid;
  }

  @override
  Future<Result<void>> deleteFolderPermanently(int folderId) async {
    calls.add('deleteFolderPermanently:$folderId');
    return const Err(UnsupportedFeatureFailure('Not supported.'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeFolderRepository fake;
  late SessionStorage session;
  late FolderSyncRepository repo;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
    // GetStorage's factory caches its default container by name only and
    // ignores `path` on every call after the first, so this has to run
    // before anything else in this isolate touches the bare `GetStorage()`
    // constructor `FolderSyncRepository` uses internally. Pointing it at a
    // directory unique to this test file keeps it off the single shared
    // `GetStorage.gs` file every other test file's default container also
    // writes to — under `flutter test`'s default parallelism, two processes
    // writing that one file at once intermittently hit a real file lock
    // error, not a bug in the repository under test.
    GetStorage(
      'GetStorage',
      Directory.systemTemp.createTempSync('folder_sync_test_').path,
    );
  });

  setUp(() async {
    await GetStorage.init();
    // A fresh namespace per test — SessionStorage isn't Get.put here, so
    // nothing else reads it and its user id can just be set directly.
    session = SessionStorage()
      ..user.value = UserData(id: 'user-${DateTime.now().microsecondsSinceEpoch}');
    fake = _FakeFolderRepository();
    repo = FolderSyncRepository(fake, session);
  });

  test('creating a folder offline assigns a temp id and shows up locally', () async {
    fake.online = false;

    final result = await repo.saveFolder(
      id: 0,
      name: 'Groceries',
      iconName: 'folder',
      colorValue: '#FF0000',
    );

    expect(result, isA<Ok<int>>());
    final tempId = result.valueOrNull!;
    expect(tempId, lessThan(0));
    expect(repo.pendingCount, 1);

    final bundle = await repo.getFolders();
    expect(bundle.valueOrNull!.folders.map((f) => f.name), contains('Groceries'));
  });

  test(
    'reconnecting syncs an offline-created folder and replaces its temp id',
    () async {
      fake.online = false;
      final createResult = await repo.saveFolder(
        id: 0,
        name: 'Groceries',
        iconName: 'folder',
        colorValue: '#FF0000',
      );
      final tempId = createResult.valueOrNull!;

      fake.online = true;
      final bundle = await repo.getFolders(); // flushes, then re-fetches

      expect(repo.pendingCount, 0);
      expect(fake.byId.values.map((f) => f.name), contains('Groceries'));
      final synced = bundle.valueOrNull!.folders.single;
      expect(synced.name, 'Groceries');
      expect(synced.id, isNot(tempId));
      expect(synced.id, greaterThanOrEqualTo(0));
    },
  );

  test(
    'a folder created offline and nested inside another offline folder '
    'resolves its parent to the real, synced id',
    () async {
      fake.online = false;
      final parentId = (await repo.saveFolder(
        id: 0,
        name: 'Parent',
        iconName: 'folder',
        colorValue: '#000000',
      )).valueOrNull!;
      final childId = (await repo.saveFolder(
        id: 0,
        parentId: parentId,
        name: 'Child',
        iconName: 'folder',
        colorValue: '#000000',
      )).valueOrNull!;
      expect(parentId, lessThan(0));
      expect(childId, lessThan(0));

      fake.online = true;
      await repo.flushPending();

      expect(repo.pendingCount, 0);
      final realParent = fake.byId.values.firstWhere((f) => f.name == 'Parent');
      final realChild = fake.byId.values.firstWhere((f) => f.name == 'Child');
      expect(realChild.parentId, realParent.id);
    },
  );

  test(
    'editing an already-synced folder offline queues the edit and shows it '
    'immediately from cache',
    () async {
      final id = (await repo.saveFolder(
        id: 0,
        name: 'Original',
        iconName: 'folder',
        colorValue: '#000000',
      )).valueOrNull!;

      fake.online = false;
      final editResult = await repo.saveFolder(
        id: id,
        name: 'Renamed',
        iconName: 'folder',
        colorValue: '#000000',
      );
      expect(editResult.valueOrNull, id);
      expect(repo.pendingCount, 1);

      final offlineBundle = await repo.getFolders();
      expect(offlineBundle.valueOrNull!.folders.single.name, 'Renamed');

      fake.online = true;
      await repo.flushPending();
      expect(repo.pendingCount, 0);
      expect(fake.byId[id]!.name, 'Renamed');
    },
  );

  test(
    'deleting a folder that never synced is handled entirely locally — no '
    'network call is made for it',
    () async {
      fake.online = false;
      final tempId = (await repo.saveFolder(
        id: 0,
        name: 'Throwaway',
        iconName: 'folder',
        colorValue: '#000000',
      )).valueOrNull!;
      fake.calls.clear();

      // Still offline, but even if it weren't: an id the server has never
      // heard of must never reach it.
      final result = await repo.deleteRestoreFolder(tempId, true);
      expect(result, isA<Ok<void>>());
      expect(
        fake.calls.any((c) => c.contains('$tempId')),
        isFalse,
        reason: 'no network call should reference a never-synced temp id',
      );

      final bundle = await repo.getFolders();
      expect(bundle.valueOrNull!.trash.single.id, tempId);
    },
  );

  test(
    'a real server rejection (not connectivity) is not treated as offline',
    () async {
      fake.online = true;
      fake.nextSaveRejection = const Err(
        ValidationFailure('Name already used.'),
      );

      final result = await repo.saveFolder(
        id: 0,
        name: 'Duplicate',
        iconName: 'folder',
        colorValue: '#000000',
      );

      expect(result, isA<Err<int>>());
      expect(result.failureOrNull, isA<ValidationFailure>());
      // Must not have been queued for a retry — this wasn't a connectivity
      // problem, retrying would just fail the same way again.
      expect(repo.pendingCount, 0);
    },
  );
}
