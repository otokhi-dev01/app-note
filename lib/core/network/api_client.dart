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
  Completer<bool>? _refreshCompleter;

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

          // The Chat server owns the account session. A Note server 401
          // must reach the caller as an error without undoing a Chat login.
          final isAccountSession401 =
              e.response?.statusCode == 401 &&
              e.requestOptions.extra['requiresAuth'] != false &&
              e.requestOptions.uri.origin ==
                  Uri.parse(AppConstants.baseUrl).origin;

          if (isAccountSession401) {
            if (await _tryRefreshSession()) {
              try {
                final retried = await _dio.fetch(e.requestOptions);
                return handler.resolve(retried);
              } on DioException {
                // The refreshed token still didn't satisfy the original
                // request — fall through to sign-out below.
              }
            }
            unawaited(Get.find<SessionStorage>().clearSession());
            unawaited(Get.offAllNamed('/login'));
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// Best-effort silent refresh, attempted once before a 401 from the
  /// account server hard-signs the user out.
  ///
  /// UNVERIFIED against the live backend: login/register never hand back a
  /// separate refresh token today (see [AuthResponse] — only `token` is
  /// parsed), so this assumes `POST /api/auth/refresh-token` accepts the
  /// just-expired access token as proof of a recent session and returns a
  /// fresh one in the same envelope shape as login. If that assumption is
  /// wrong, this fails fast and the caller falls through to the pre-existing
  /// hard-logout — it cannot make 401 handling any worse than it already was.
  Future<bool> _tryRefreshSession() {
    final inFlight = _refreshCompleter;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    Future(() async {
      try {
        final session = Get.find<SessionStorage>();
        final currentToken = session.token.value;
        if (currentToken == null || currentToken.isEmpty) {
          completer.complete(false);
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
          completer.complete(false);
          return;
        }
        await session.saveSession(auth.token, session.user.value ?? auth.user);
        completer.complete(true);
      } catch (_) {
        completer.complete(false);
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
