import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;

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
    defaultValue: 'https://note.piisiit.com',
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
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final session = Get.find<SessionStorage>();
          if (session.isLoggedIn) {
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
              _printErrorResponse(e.response?.data);
            }
          }
          if (e.response?.statusCode == 401) {
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
