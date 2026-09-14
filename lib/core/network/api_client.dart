import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
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
          if (options.extra['requiresAuth'] == false) {
            options.headers.removeWhere(
              (key, _) => key.toLowerCase() == 'authorization',
            );
          } else if (session.isLoggedIn) {
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
          // The refresh call itself failing is handled by its own caller
          // (_tryRefreshSession's try/catch) — don't also run the sign-out
          // logic below for it, or a failed refresh would fire it twice.
          if (e.requestOptions.extra['isTokenRefresh'] == true) {
            return handler.next(e);
          }
          // Both the Chat and Note servers accept the same bearer token
          // from login, so a 401 from either one is worth one silent
          // refresh-and-retry — including the Note server 401ing right
          // after login (see FolderRemoteDataSource): that's a real,
          // just-issued token the Note server hasn't caught up on yet, the
          // same class of problem a refresh-and-retry fixes on Chat.
          final isUnauthorized =
              e.response?.statusCode == 401 &&
              e.requestOptions.extra['requiresAuth'] != false;

          if (isUnauthorized) {
            final refreshResult = await _tryRefreshSession();
            if (refreshResult == _RefreshResult.refreshed) {
              try {
                final retried = await _dio.fetch(e.requestOptions);
                return handler.resolve(retried);
              } on DioException {
                // The refreshed token still didn't satisfy the original
                // request — fall through below.
              }
            }
            // A definite rejection — either server actively said "no,
            // this session is done" to the refresh attempt, or a fresh
            // token still didn't satisfy the retry — means the session
            // really is over, from either server, since both accept the
            // same token. `unreachable` must never sign the user out: that
            // just means the refresh call itself couldn't be completed
            // (offline, timeout, DNS), which says nothing about whether
            // the session is still good.
            if (refreshResult != _RefreshResult.unreachable) _forceSignOut();
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

  /// Best-effort silent refresh, attempted once before a 401 hard-signs the
  /// user out.
  ///
  /// UNVERIFIED against the live backend: login/register never hand back a
  /// separate refresh token today (see [AuthResponse] — only `token` is
  /// parsed), so this assumes `POST /api/auth/refresh-token` accepts the
  /// just-expired access token as proof of a recent session and returns a
  /// fresh one in the same envelope shape as login. As of 2026-09,
  /// confirmed against the live backend: that assumption is wrong — the
  /// endpoint answers every attempt with `400 Bad Request`, so this never
  /// actually succeeds today. It stays in place because it's harmless (one
  /// extra request before a 401 that was going to fail anyway) and starts
  /// working for free the moment the backend contract is fixed. See the
  /// caller in `onError` for what happens when this fails.
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
          if (kDebugMode) {
            debugPrint('[API] Silent refresh rejected: ${response.data}');
          }
          completer.complete(_RefreshResult.rejected);
          return;
        }
        await session.saveSession(auth.token, session.user.value ?? auth.user);
        completer.complete(_RefreshResult.refreshed);
      } on DioException catch (e) {
        // A response means the server was reached and it said no — the
        // session really is done. Anything else (timeout, no connectivity,
        // DNS failure) means the device just couldn't reach the server this
        // moment, which is not evidence the session is bad.
        final result = e.response != null
            ? _RefreshResult.rejected
            : _RefreshResult.unreachable;
        if (kDebugMode) {
          debugPrint('[API] Silent refresh call failed (${result.name}): $e');
        }
        completer.complete(result);
      } catch (e) {
        if (kDebugMode) debugPrint('[API] Silent refresh call failed: $e');
        completer.complete(_RefreshResult.unreachable);
      } finally {
        _refreshCompleter = null;
      }
    });

    return completer.future;
  }

  bool _isSensitiveEndpoint(String path) => path.contains('/api/auth/');
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

  /// The server was reached and it said this session is no good — a 401 on
  /// the refresh call itself, a malformed-request rejection, or a response
  /// the app doesn't recognize as success.
  rejected,

  /// The refresh call itself never got a response — no connectivity,
  /// timeout, DNS failure. Says nothing about whether the session is good.
  unreachable,
}
