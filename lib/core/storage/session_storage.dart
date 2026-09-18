import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import 'package:Note/features/auth/data/models/auth_model.dart';
import 'package:Note/core/error/exceptions.dart';

/// Persists the bearer token and signed-in user in the platform keystore.
///
/// Exposed as observables so the API client can attach the token and the UI can
/// react to sign-in/sign-out without a separate event bus.
class SessionStorage extends GetxService {
  final _storage = const FlutterSecureStorage();
  int _revision = 0;
  Future<void> _pendingWrite = Future.value();

  Future<void> _serializeWrite(Future<void> Function() action) {
    final operation = _pendingWrite.then((_) => action());
    _pendingWrite = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  final user = Rxn<UserData>();
  final token = RxnString();

  bool get isLoggedIn => token.value?.isNotEmpty == true;

  @override
  void onInit() {
    super.onInit();
    loadSession();
  }

  Future<void> loadSession() async {
    final revision = _revision;
    try {
      await _pendingWrite;
      final savedToken = await _storage.read(key: 'token');
      final userJson = await _storage.read(key: 'user');
      final savedUser = userJson == null
          ? null
          : UserData.fromJson(jsonDecode(userJson));
      if (revision != _revision) return;
      user.value = savedUser;
      token.value = savedToken == null || savedToken.isEmpty
          ? null
          : savedToken;
    } catch (e) {
      // A corrupt payload or an unavailable keystore (locked device, missing
      // plugin in tests) must not crash startup — treat it as signed out.
      if (kDebugMode) debugPrint('[SESSION] Could not restore session: $e');
      if (revision == _revision) {
        token.value = null;
        user.value = null;
      }
    }
  }

  Future<void> saveSession(String newToken, UserData userData) {
    final revision = ++_revision;
    return _serializeWrite(() async {
      if (revision != _revision) {
        throw const StorageException(
          'Sign-in was interrupted. Please try again.',
        );
      }
      try {
        await _storage.write(key: 'user', value: jsonEncode(userData.toJson()));
        await _storage.write(key: 'token', value: newToken);
      } catch (_) {
        token.value = null;
        user.value = null;
        // Remove partial credentials without deleting unrelated encryption keys.
        for (final key in ['token', 'user']) {
          try {
            await _storage.delete(key: key);
          } catch (_) {}
        }
        throw const StorageException(
          'Could not securely save your sign-in on this device. Please try again.',
        );
      }
      if (revision != _revision) {
        throw const StorageException(
          'Sign-in was interrupted. Please try again.',
        );
      }
      // Token listeners must see the matching user and a persisted session.
      user.value = userData;
      token.value = newToken;
    });
  }

  Future<void> clearSession() async {
    _revision++;
    token.value = null;
    user.value = null;
    await _serializeWrite(() => _storage.deleteAll());
  }
}
