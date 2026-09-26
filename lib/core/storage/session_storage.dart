import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:Note/core/network/access_token.dart';
import 'package:Note/core/network/auth_diagnostics.dart';
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
  int get revision => _revision;

  /// Requests must not pair old credentials with an in-progress login's
  /// revision. Include writes queued while an earlier write is settling.
  Future<void> waitForPendingWrites() async {
    while (true) {
      final pending = _pendingWrite;
      await pending;
      if (identical(pending, _pendingWrite)) return;
    }
  }

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
      final normalized = AccessToken.normalize(savedToken);
      final savedRefreshToken = await _storage.read(key: 'refresh_token');
      final userJson = await _storage.read(key: 'user');
      final savedUser = userJson == null || normalized.value.isEmpty
          ? null
          : UserData.fromJson(jsonDecode(userJson));
      if (revision != _revision) return;
      // Repair legacy values once, without touching any other storage key.
      if (savedToken != null && savedToken != normalized.value) {
        await _serializeWrite(() async {
          if (revision != _revision) return;
          if (normalized.value.isEmpty) {
            await _storage.delete(key: 'token');
          } else {
            await _storage.write(key: 'token', value: normalized.value);
          }
        });
        if (revision != _revision) return;
      }
      if (kDebugMode) {
        debugPrint(
          '[SESSION] Restored token: ${AuthDiagnostics.describeToken(savedToken)}',
        );
      }
      restoreFailed.value = false;
      user.value = savedUser;
      refreshToken.value = normalized.value.isEmpty ? null : savedRefreshToken;
      token.value = normalized.value.isEmpty ? null : normalized.value;
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
    final normalized = AccessToken.normalize(newToken);
    final rawToken = normalized.value;
    if (rawToken.isEmpty) {
      throw const StorageException(
        'The server returned an empty sign-in token.',
      );
    }
    if (kDebugMode) {
      debugPrint(
        '[SESSION] Saving token: ${AuthDiagnostics.describeToken(newToken)}',
      );
    }
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
        await _storage.write(key: 'token', value: rawToken);
        if (await _storage.read(key: 'token') != rawToken ||
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
      token.value = rawToken;
    });
  }

  /// A terminal 401 invalidates only the access-token key. Retained account
  /// metadata and refresh credentials cannot restore a session without it.
  Future<void> invalidateToken() async {
    _revision++;
    token.value = null;
    refreshToken.value = null;
    user.value = null;
    restoreFailed.value = false;
    await _serializeWrite(() => _storage.delete(key: 'token'));
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
