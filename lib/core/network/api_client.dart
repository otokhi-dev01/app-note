import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, FormData;
import 'package:Note/core/constants/app_constants.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/auth/data/models/auth_model.dart';

/// Owns the configured [Dio] instance: base URL, timeouts, auth header
/// injection, logging, and 401 handling.
///
/// Datasources are the only things that touch this. Nothing above the data
/// layer should import Dio.
class ApiClient extends GetxService {
  late Dio _dio;

  /// In-flight silent-refresh attempt, shared by every request that 401s
  /// around the same moment so they don't each fire their own refresh call.
  Future<_RefreshResult>? _refreshFuture;
  String? _recoveryToken;
  _RefreshResult? _lastRecovery;
  DateTime? _retryRecoveryAfter;

  /// Base URL for the Note API. Override with
  /// `--dart-define=PIISIIT_NOTE_BASE_URL=https://...`
  static const String baseUrl = String.fromEnvironment(
    'PIISIIT_NOTE_BASE_URL',
    defaultValue: AppConstants.noteBaseUrl,
  );
  Dio get dio => _dio;
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
          if (options.extra['requiresAuth'] != false) await session.ready;
          for (final key
              in options.headers.keys
                  .where((key) => key.toLowerCase() == 'authorization')
                  .toList()) {
            options.headers.remove(key);
          }
          if (options.extra['requiresAuth'] != false && session.isLoggedIn) {
            options.headers['Authorization'] = 'Bearer ${session.token.value}';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (e, handler) async {
          if (kDebugMode) {
            // Only log error body if not a sensitive endpoint
            if (!_isSensitiveEndpoint(e.requestOptions.path)) {
              final request = e.requestOptions;
              debugPrint(
                '[API] ${request.method} ${request.uri.origin}${request.uri.path} '
                'status=${e.response?.statusCode} type=${e.type.name} '
                'authenticated=${request.headers.containsKey('Authorization')}',
              );
              _printErrorResponse(e.response?.data);
            }
          }
          // Recovery requests and the one permitted retry must never start
          // another recovery cycle through this interceptor.
          if (e.requestOptions.extra['isTokenRefresh'] == true ||
              e.requestOptions.extra['authRetried'] == true) {
            return handler.next(e);
          }
          final request = e.requestOptions;
          final isNoteRequest = request.uri.origin == Uri.parse(baseUrl).origin;
          final isChatRequest =
              request.uri.origin == Uri.parse(AppConstants.baseUrl).origin;
          final isUnauthorized =
              e.response?.statusCode == 401 &&
              request.extra['requiresAuth'] != false &&
              (isNoteRequest || isChatRequest);

          if (isUnauthorized) {
            final session = Get.find<SessionStorage>();
            final tokenBeforeRecovery = session.token.value;
            // A public/early request has no session to revoke. In particular,
            // never erase persisted credentials because it ran before restore.
            if (request.headers['Authorization'] == null ||
                tokenBeforeRecovery == null ||
                tokenBeforeRecovery.isEmpty) {
              return handler.next(e);
            }
            // A concurrent request may already have refreshed this token.
            final alreadyRefreshed =
                request.headers['Authorization'] !=
                'Bearer $tokenBeforeRecovery';
            final refreshResult = alreadyRefreshed
                ? _RefreshResult.refreshed
                : await _tryRefreshSession(tokenBeforeRecovery);
            if (refreshResult == _RefreshResult.refreshed) {
              final retryToken = session.token.value;
              try {
                final retried = await _dio.fetch(
                  request.copyWith(
                    data: request.data is FormData
                        ? (request.data as FormData).clone()
                        : request.data,
                    extra: {...request.extra, 'authRetried': true},
                  ),
                );
                return handler.resolve(retried);
              } on DioException catch (retryError) {
                // Preserve the actual retry failure (including timeouts/5xx).
                e = retryError;
                if (isChatRequest &&
                    e.response?.statusCode == 401 &&
                    session.token.value == retryToken) {
                  _forceSignOut();
                } else if (isNoteRequest &&
                    e.response?.statusCode == 401 &&
                    session.token.value == retryToken) {
                  // The account server just issued this token. Refreshing it
                  // repeatedly cannot repair a Note-side authorization failure.
                  _recoveryToken = retryToken;
                  _lastRecovery = _RefreshResult.accountValid;
                  _retryRecoveryAfter = DateTime.now().add(
                    const Duration(seconds: 30),
                  );
                }
              }
            } else if (refreshResult == _RefreshResult.rejected &&
                session.token.value == tokenBeforeRecovery) {
              // An explicit rejection by the account server invalidates the
              // session even when the original request was to the Note server.
              _forceSignOut();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// Clears the session and sends the user to `/login`.
  ///
  /// `clearSession()` updates `SessionStorage.token`/`.user` synchronously
  /// before its first `await`, so callers (and tests) can rely on the
  /// session already reading as signed-out the moment this method returns —
  /// that's why it's fired off with `unawaited` rather than deferred onto a
  /// new event-loop turn, which would delay that visible effect for no
  /// reason.
  ///
  /// `Get.offAllNamed`, by contrast, throws synchronously when there's no
  /// navigator mounted yet (a real possibility this early in a request's
  /// lifecycle, and always true in a headless test). Called directly from
  /// `onError` without this guard, that throw would skip `handler.next(e)`
  /// entirely and Dio would surface a generic, unrelated connection error to
  /// the caller instead of the real 401 — replacing a clear "your session
  /// expired" with a confusing "could not reach the server" — so only this
  /// part gets caught.
  void _forceSignOut() {
    unawaited(Get.find<SessionStorage>().clearSession());
    try {
      unawaited(Get.offAllNamed('/login'));
    } catch (error) {
      if (kDebugMode) debugPrint('[API] Post-401 navigation failed: $error');
    }
  }

  /// Share recovery for a token and briefly back off after a failed attempt.
  /// A newly signed-in account must never consume an older account's recovery.
  Future<_RefreshResult> _tryRefreshSession(String token) {
    if (_recoveryToken == token) {
      if (_refreshFuture != null) return _refreshFuture!;
      if (_retryRecoveryAfter?.isAfter(DateTime.now()) == true) {
        return Future.value(_lastRecovery!);
      }
    }
    _recoveryToken = token;
    _lastRecovery = null;
    _retryRecoveryAfter = null;
    final session = Get.find<SessionStorage>();
    final future = _recoverSession(session, token).then((result) {
      if (_recoveryToken == token) _refreshFuture = null;
      if (session.token.value != token && result != _RefreshResult.refreshed) {
        return _RefreshResult.unreachable;
      }
      if (_recoveryToken == token) {
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
    String currentToken,
  ) async {
    final refreshToken = session.refreshToken.value;
    if (refreshToken == null || refreshToken.isEmpty) {
      // Older app versions saved only the access token. Never send an empty
      // refresh request or substitute the access token for a refresh token.
      return _verifySession(currentToken);
    }
    try {
      final response = await _dio.post(
        '${AppConstants.authBaseUrl}${AppConstants.refreshTokenEndpoint}',
        data: {'refreshToken': refreshToken},
        options: Options(
          extra: {'isTokenRefresh': true, 'requiresAuth': false},
        ),
      );
      final auth = AuthResponse.fromJson(
        Map<String, dynamic>.from(
          response.data is Map ? response.data as Map : {},
        ),
        statusCode: response.statusCode,
      );
      if (session.token.value != currentToken ||
          session.refreshToken.value != refreshToken) {
        return _RefreshResult.unreachable;
      }
      if (!auth.isSuccess || auth.token.trim().isEmpty) {
        return await _verifySession(currentToken);
      }
      await session.saveSession(
        auth.token,
        session.user.value ?? auth.user,
        // Some servers rotate refresh tokens; others return only access tokens.
        refreshToken: auth.refreshToken.isEmpty
            ? refreshToken
            : auth.refreshToken,
      );
      return _RefreshResult.refreshed;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (session.token.value != currentToken) {
        return _RefreshResult.unreachable;
      }
      if (kDebugMode) {
        debugPrint(
          '[API] Token refresh failed (status=$status, type=${e.type.name}).',
        );
      }
      if (status == 401 || status == 403) return _RefreshResult.rejected;
      if (status == 400 || status == 404 || status == 405) {
        return _verifySession(currentToken);
      }
      return _RefreshResult.unreachable;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[API] Could not save renewed session: ${e.runtimeType}');
      }
      return _RefreshResult.unreachable;
    }
  }

  Future<_RefreshResult> _verifySession(String expectedToken) async {
    try {
      final response = await _dio.get(
        '${AppConstants.authBaseUrl}${AppConstants.sessionsEndpoint}',
        options: Options(extra: {'isTokenRefresh': true}),
      );
      if (Get.find<SessionStorage>().token.value != expectedToken) {
        return _RefreshResult.unreachable;
      }
      final body = response.data;
      if (body is! Map || (body['success'] ?? body['Success']) == false) {
        return _RefreshResult.unreachable;
      }
      if (kDebugMode) {
        debugPrint(
          '[API] Account session is valid; the requesting service rejected access.',
        );
      }
      return _RefreshResult.accountValid;
    } on DioException catch (e) {
      return e.response?.statusCode == 401 || e.response?.statusCode == 403
          ? _RefreshResult.rejected
          : _RefreshResult.unreachable;
    } catch (_) {
      return _RefreshResult.unreachable;
    }
  }

  bool _isSensitiveEndpoint(String path) =>
      path.contains('/api/auth/') || Uri.parse(path).path == '/upload-document';
  void _printErrorResponse(Object? data) {
    if (!kDebugMode || data == null) return;
    final String text = data.toString();
    const int maxLength = 1000;
    debugPrint(
      text.length > maxLength
          ? '${text.substring(0, maxLength)}... [truncated]'
          : text,
    );
  }
}

/// Outcome of [ApiClient._tryRefreshSession].
enum _RefreshResult {
  /// Got a fresh token; the caller should retry the original request.
  refreshed,

  /// The account server explicitly rejected the session (401 or 403).
  rejected,

  /// Chat accepts the account, but another service rejected the request.
  accountValid,

  /// Recovery could not produce a token; the session was not rejected.
  unreachable,
}
