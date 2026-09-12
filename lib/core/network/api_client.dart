import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;

import 'package:Note/core/constants/app_constants.dart';
import 'package:Note/core/storage/session_storage.dart';

/// Owns the configured [Dio] instance: base URL, timeouts, auth header
/// injection, logging, and 401 handling.
///
/// Datasources are the only things that touch this. Nothing above the data
/// layer should import Dio.
class ApiClient extends GetxService {
  late Dio _dio;

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
        onError: (e, handler) {
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
          // The Chat server owns the account session. A Note server 401
          // must reach the caller as an error without undoing a Chat login.
          if (e.response?.statusCode == 401 &&
              e.requestOptions.extra['requiresAuth'] != false &&
              e.requestOptions.uri.origin ==
                  Uri.parse(AppConstants.baseUrl).origin) {
            Get.find<SessionStorage>().clearSession();
            Get.offAllNamed('/login');
          }
          return handler.next(e);
        },
      ),
    );
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
