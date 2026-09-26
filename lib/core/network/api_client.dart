import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, FormData;
import 'package:Note/core/constants/app_constants.dart';
import 'package:Note/core/network/access_token.dart';
import 'package:Note/core/network/auth_diagnostics.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';

/// HTTP transport with normalized credentials and bounded session recovery.
class ApiClient extends GetxService {
  /// Chat documents this endpoint. Pass null for a server without refresh.
  ApiClient({this.refreshTokenEndpoint = AppConstants.refreshTokenEndpoint});

  final String? refreshTokenEndpoint;
  bool _refreshEndpointAvailable = true;
  late Dio _dio;
  Future<_RefreshResult>? _refreshFuture;
  int? _recoveryRevision;
  _RefreshResult? _lastRecovery;
  DateTime? _retryRecoveryAfter;

  static const String baseUrl = String.fromEnvironment(
    'PIISIIT_NOTE_BASE_URL',
    defaultValue: AppConstants.noteBaseUrl,
  );

  Dio get dio => _dio;

  bool _isAccountOrNote(RequestOptions request) =>
      request.uri.origin == Uri.parse(baseUrl).origin ||
      request.uri.origin == Uri.parse(AppConstants.baseUrl).origin;

  bool _requiresAuth(RequestOptions request) =>
      request.extra['requiresAuth'] != false &&
      // Protect login even when a caller forgets requiresAuth: false.
      request.uri.path != '/api/auth/login' &&
      request.uri.path != '/api/auth/register';

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': AppConstants.contentTypeJson,
          'Accept': AppConstants.contentTypeJson,
        },
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final session = Get.find<SessionStorage>();
          final authenticated =
              _requiresAuth(options) && _isAccountOrNote(options);
          if (authenticated) {
            await session.ready;
            int waitingRevision;
            do {
              waitingRevision = session.revision;
              await session.waitForPendingWrites();
            } while (waitingRevision != session.revision);
            final retryRevision = options.extra['authRetrySessionRevision'];
            if (retryRevision != null && retryRevision != session.revision) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.cancel,
                  message:
                      'The session changed before the request could retry.',
                ),
              );
            }
          }
          for (final key
              in options.headers.keys
                  .where((key) => key.toLowerCase() == 'authorization')
                  .toList()) {
            options.headers.remove(key);
          }
          if (authenticated) {
            final normalized = AccessToken.normalize(session.token.value);
            options.extra['authSessionRevision'] = session.revision;
            if (normalized.value.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer ${normalized.value}';
            }
            if (kDebugMode && options.extra['isTokenRefresh'] != true) {
              debugPrint(
                '[API] Request token: ${AuthDiagnostics.describeToken(session.token.value)}',
              );
            }
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            final request = response.requestOptions;
            debugPrint(
              '[API] ${request.method} ${request.uri.origin}${request.uri.path} status=${response.statusCode}',
            );
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          var failure = error;
          final request = error.requestOptions;
          final challenges =
              error.response?.headers['www-authenticate'] ?? const <String>[];
          if (kDebugMode) {
            debugPrint(
              '[API] ${request.method} ${request.uri.origin}${request.uri.path} '
              'status=${error.response?.statusCode} type=${error.type.name} '
              'authorizationAttached=${request.headers.containsKey('Authorization')}',
            );
            if (error.response?.statusCode == 401) {
              debugPrint(
                '[API] Auth diagnostics: ${AuthDiagnostics.describe(authorization: request.headers['Authorization']?.toString(), challenges: challenges)}',
              );
            }
          }

          // The outer request owns recovery and invalidation for its one retry.
          if (request.extra['isTokenRefresh'] == true ||
              request.extra['authRetried'] == true ||
              error.response?.statusCode != 401 ||
              !_requiresAuth(request) ||
              !_isAccountOrNote(request)) {
            return handler.next(error);
          }

          final session = Get.find<SessionStorage>();
          final revision = request.extra['authSessionRevision'];
          // An old account's response must never revoke or replay as a new one.
          // A locked keystore also isn't evidence that saved credentials failed.
          if (session.restoreFailed.value || revision != session.revision) {
            return handler.next(error);
          }
          final token = AccessToken.normalize(session.token.value).value;
          final reason = AuthDiagnostics.serverReason(challenges);
          if (_isValidationMismatch(reason)) {
            _logValidationMismatch(reason);
            if (!kDebugMode) {
              await _invalidateSession(session, session.revision);
            } else {
              debugPrint(
                '[API] [DEBUG MODE] Skipping session invalidation for $reason to allow backend debugging.',
              );
            }
            return handler.next(error);
          }
          if (token.isEmpty || request.headers['Authorization'] == null) {
            await _invalidateSession(session, session.revision);
            return handler.next(error);
          }

          final recovery = await _tryRefreshSession(
            session,
            token,
            session.revision,
          );
          if (recovery == _RefreshResult.refreshed) {
            if (session.revision != (revision as int) + 1) {
              return handler.next(error);
            }
            final retryRevision = session.revision;
            try {
              final response = await _dio.fetch(
                request.copyWith(
                  data: request.data is FormData
                      ? (request.data as FormData).clone()
                      : request.data,
                  extra: {
                    ...request.extra,
                    'authRetried': true,
                    'authRetrySessionRevision': retryRevision,
                  },
                ),
              );
              return handler.resolve(response);
            } on DioException catch (retryError) {
              failure = retryError;
              if (retryError.response?.statusCode == 401) {
                final retryReason = AuthDiagnostics.serverReason(
                  retryError.response?.headers['www-authenticate'] ?? const [],
                );
                if (_isValidationMismatch(retryReason)) {
                  _logValidationMismatch(retryReason);
                }
                await _invalidateSession(session, retryRevision);
              }
            }
          } else if (recovery == _RefreshResult.rejected) {
            await _invalidateSession(session, revision as int);
          }
          handler.next(failure);
        },
      ),
    );
  }

  bool _isValidationMismatch(String reason) =>
      reason == 'signature_rejected' ||
      reason == 'issuer_rejected' ||
      reason == 'audience_rejected';

  void _logValidationMismatch(String reason) {
    if (kDebugMode) {
      debugPrint(
        '[API] Token validation failed: $reason. If a fresh login repeats '
        'this failure, check backend signing keys, algorithm, issuer, audience '
        'and production environment.',
      );
    }
  }

  Future<void> _invalidateSession(
    SessionStorage session,
    int expectedRevision,
  ) async {
    if (session.revision != expectedRevision) return;
    try {
      // Synchronously invalidates observables; only the token key is deleted.
      await session.invalidateToken();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[API] Token removal failed: ${error.runtimeType}');
      }
    }
    // Do not redirect a new login completed while deletion was pending.
    if (session.revision != expectedRevision + 1 || session.isLoggedIn) return;
    if (kDebugMode) {
      debugPrint('[API] Access token invalidated; sign-in required.');
    }
    try {
      if (Get.currentRoute != '/login') unawaited(Get.offAllNamed('/login'));
    } catch (error) {
      // Headless tests/early startup may have no navigator. Preserve the 401.
      if (kDebugMode) {
        debugPrint(
          '[API] Post-401 navigation unavailable: ${error.runtimeType}',
        );
      }
    }
  }

  Future<_RefreshResult> _tryRefreshSession(
    SessionStorage session,
    String token,
    int revision,
  ) {
    if (_recoveryRevision == revision) {
      if (_refreshFuture != null) return _refreshFuture!;
      if (_retryRecoveryAfter?.isAfter(DateTime.now()) == true) {
        return Future.value(_lastRecovery!);
      }
    }
    _recoveryRevision = revision;
    _lastRecovery = null;
    _retryRecoveryAfter = null;
    final future = _recoverSession(session, token, revision).then((result) {
      if (_recoveryRevision == revision) {
        _refreshFuture = null;
        if (result != _RefreshResult.refreshed) {
          _lastRecovery = result;
          _retryRecoveryAfter = DateTime.now().add(const Duration(seconds: 30));
        }
      }
      return result;
    });
    _refreshFuture = future;
    return future;
  }

  Future<_RefreshResult> _recoverSession(
    SessionStorage session,
    String token,
    int revision,
  ) async {
    final refreshToken = session.refreshToken.value;
    final endpoint = refreshTokenEndpoint;
    if (!_refreshEndpointAvailable ||
        endpoint == null ||
        endpoint.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return _RefreshResult.rejected;
    }
    try {
      final response = await _dio.post(
        '${AppConstants.authBaseUrl}$endpoint',
        data: {'refreshToken': refreshToken},
        options: Options(
          extra: {'isTokenRefresh': true, 'requiresAuth': false},
        ),
      );
      if (session.revision != revision) return _RefreshResult.unreachable;
      final auth = AuthResponse.fromJson(
        Map<String, dynamic>.from(
          response.data is Map ? response.data as Map : {},
        ),
        statusCode: response.statusCode,
      );
      final renewed = AccessToken.normalize(auth.token).value;
      if (!auth.isSuccess || renewed.isEmpty || renewed == token) {
        return _RefreshResult.rejected;
      }
      await session.saveSession(
        auth.token,
        session.user.value ?? auth.user,
        refreshToken: auth.refreshToken.isEmpty
            ? refreshToken
            : auth.refreshToken,
      );
      if (session.revision != revision + 1) return _RefreshResult.unreachable;
      // saveSession uses a revision guard, so a late refresh cannot resurrect a
      // signed-out account or overwrite a new login.
      return _RefreshResult.refreshed;
    } on DioException catch (error) {
      if (session.revision != revision) return _RefreshResult.unreachable;
      final status = error.response?.statusCode;
      if (kDebugMode) {
        debugPrint(
          '[API] Token refresh failed: status=$status type=${error.type.name}',
        );
      }
      if (status == 404 || status == 405) _refreshEndpointAvailable = false;
      if (status == 400 ||
          status == 401 ||
          status == 403 ||
          status == 404 ||
          status == 405) {
        return _RefreshResult.rejected;
      }
      return _RefreshResult.unreachable;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[API] Session renewal unavailable: ${error.runtimeType}');
      }
      return _RefreshResult.unreachable;
    }
  }
}

enum _RefreshResult { refreshed, rejected, unreachable }
