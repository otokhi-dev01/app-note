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
  Completer<_RefreshResult>? _refreshCompleter;

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
        onRequest: (options, handler) {
          final session = Get.find<SessionStorage>();
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
            // A concurrent request may already have refreshed this token.
            final alreadyRefreshed =
                tokenBeforeRecovery != null &&
                request.headers['Authorization'] !=
                    'Bearer $tokenBeforeRecovery';
            final refreshResult = alreadyRefreshed
                ? _RefreshResult.refreshed
                : await _tryRefreshSession();
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

  /// Coalesces concurrent recovery requests. If refresh is unsupported or
  /// returns an unusable response, verify the existing session with the
  /// account profile endpoint before deciding to sign out.
  Future<_RefreshResult> _tryRefreshSession() {
    final inFlight = _refreshCompleter;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<_RefreshResult>();
    _refreshCompleter = completer;

    Future(() async {
      try {
        final session = Get.find<SessionStorage>();
        final currentToken = session.token.value;
        if (currentToken == null || currentToken.isEmpty) {
          completer.complete(_RefreshResult.rejected);
          return;
        }
        final response = await _dio.post(
          '${AppConstants.authBaseUrl}${AppConstants.refreshTokenEndpoint}',
          options: Options(extra: {'isTokenRefresh': true}),
        );
        final auth = AuthResponse.fromJson(
          Map<String, dynamic>.from(
            response.data is Map ? response.data as Map : {},
          ),
          statusCode: response.statusCode,
        );
        if (!auth.isSuccess || auth.token.isEmpty) {
          completer.complete(await _verifySession());
          return;
        }
        if (session.token.value != currentToken) {
          completer.complete(_RefreshResult.unreachable);
          return;
        }
        await session.saveSession(auth.token, session.user.value ?? auth.user);
        completer.complete(_RefreshResult.refreshed);
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final result = status == 401 || status == 403
            ? _RefreshResult.rejected
            : status == 400 || status == 404 || status == 405
            ? await _verifySession()
            : _RefreshResult.unreachable;
        if (kDebugMode) {
          debugPrint(
            '[API] Session recovery: ${result.name} (status=$status).',
          );
        }
        completer.complete(result);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[API] Session recovery failed: ${e.runtimeType}');
        }
        completer.complete(_RefreshResult.unreachable);
      } finally {
        _refreshCompleter = null;
      }
    });

    return completer.future;
  }

  Future<_RefreshResult> _verifySession() async {
    try {
      await _dio.get(
        '${AppConstants.userApiUrl}${AppConstants.userProfileEndpoint}',
        options: Options(extra: {'isTokenRefresh': true}),
      );
      // A valid Chat session does not make a Note-only rejection recoverable.
      return _RefreshResult.unreachable;
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

  /// Recovery could not produce a token; the session was not rejected.
  unreachable,
}
