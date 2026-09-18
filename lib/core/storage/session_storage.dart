import 'dart:async';
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
  Future<void>? _loading;
  late final Future<void> ready = loadSession();
  final restoreFailed = false.obs;
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
  final refreshToken = RxnString();

  bool get isLoggedIn => token.value?.isNotEmpty == true;

  @override
  void onInit() {
    super.onInit();
    unawaited(ready);
  }

  Future<void> loadSession() =>
      _loading ??= _restoreSession().whenComplete(() => _loading = null);

  Future<void> _restoreSession() async {
    final revision = _revision;
    try {
      await _pendingWrite;
      final savedToken = await _storage.read(key: 'token');
      final savedRefreshToken = await _storage.read(key: 'refresh_token');
      final userJson = await _storage.read(key: 'user');
      final savedUser = userJson == null
          ? null
          : UserData.fromJson(jsonDecode(userJson));
      if (revision != _revision) return;
      restoreFailed.value = false;
      user.value = savedUser;
      refreshToken.value = savedRefreshToken;
      token.value = savedToken == null || savedToken.isEmpty
          ? null
          : savedToken;
    } catch (e) {
      // A temporarily unavailable keystore is not proof of sign-out. Keep
      // saved credentials intact and let the splash screen offer a retry.
      if (kDebugMode) {
        debugPrint('[SESSION] Could not restore session: ${e.runtimeType}');
      }
      if (revision == _revision) {
        restoreFailed.value = true;
      }
    }
  }

  Future<void> saveSession(
    String newToken,
    UserData userData, {
    String? refreshToken,
  }) {
    final newRefreshToken = refreshToken == null || refreshToken.isEmpty
        ? null
        : refreshToken;
    final revision = ++_revision;
    return _serializeWrite(() async {
      if (revision != _revision) {
        throw const StorageException(
          'Sign-in was interrupted. Please try again.',
        );
      }
      try {
        final encodedUser = jsonEncode(userData.toJson());
        await _storage.write(key: 'user', value: encodedUser);
        if (newRefreshToken == null) {
          await _storage.delete(key: 'refresh_token');
        } else {
          await _storage.write(key: 'refresh_token', value: newRefreshToken);
        }
        await _storage.write(key: 'token', value: newToken);
        if (await _storage.read(key: 'token') != newToken ||
            await _storage.read(key: 'refresh_token') != newRefreshToken ||
            await _storage.read(key: 'user') != encodedUser) {
          throw const StorageException(
            'The saved session could not be verified.',
          );
        }
      } catch (_) {
        token.value = null;
        this.refreshToken.value = null;
        user.value = null;
        // Remove partial credentials without deleting unrelated encryption keys.
        for (final key in ['token', 'refresh_token', 'user']) {
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
      restoreFailed.value = false;
      user.value = userData;
      this.refreshToken.value = newRefreshToken;
      token.value = newToken;
    });
  }

  Future<void> clearSession() async {
    _revision++;
    token.value = null;
    refreshToken.value = null;
    user.value = null;
    restoreFailed.value = false;
    await _serializeWrite(() async {
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'refresh_token');
      await _storage.delete(key: 'user');
    });
  }
}
