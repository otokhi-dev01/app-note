import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'session_service.dart';

/// Thrown when the app asks for something the backend does not implement.
///
/// Carries a user-presentable [message] so controllers can surface the real
/// reason instead of a generic failure.
class ApiUnsupportedException implements Exception {
  final String message;
  const ApiUnsupportedException(this.message);

  @override
  String toString() => 'ApiUnsupportedException: $message';
}

/// What the PiisiitNoteApi backend actually supports.
///
/// Verified against https://note.piisiit.com/swagger/v1/swagger.json (v1) on
/// 2026-08-17. Flip these to `true` once the endpoints ship, and the UI will
/// re-enable the corresponding actions automatically.
class ApiCapabilities {
  ApiCapabilities._();

  /// No /api/note/permanent-delete, /api/note/empty-trash, or
  /// /api/folder/permanent-delete route exists. Trash is soft-delete only.
  static const bool permanentDelete = false;

  /// No /api/auth/forgot-password route exists.
  static const bool forgotPassword = false;
}

class ApiService extends GetxService {
  late Dio _dio;

  // Base URL for Note API. Can be overridden with --dart-define=PIISIIT_NOTE_BASE_URL=https://...
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
          if (kDebugMode) {
            debugPrint("--> ${options.method} ${options.uri}");
            if (!_isSensitiveEndpoint(options.path) && options.data != null) {
              debugPrint("Request Data: ${options.data}");
            }
          }

          final session = Get.find<SessionService>();
          if (session.isLoggedIn) {
            options.headers['Authorization'] = 'Bearer ${session.token.value}';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              "<-- ${response.statusCode} ${response.requestOptions.uri}",
            );
          }
          return handler.next(response);
        },
        onError: (e, handler) {
          if (kDebugMode) {
            debugPrint(
              "<-- ERROR ${e.response?.statusCode} ${e.requestOptions.uri}",
            );
            // Only log error body if not a sensitive endpoint
            if (!_isSensitiveEndpoint(e.requestOptions.path)) {
              _printErrorResponse(e.response?.data);
            }
          }
          if (e.response?.statusCode == 401) {
            Get.find<SessionService>().clearSession();
            Get.offAllNamed('/login');
          }
          return handler.next(e);
        },
      ),
    );
  }

  bool _isSensitiveEndpoint(String path) {
    return path.contains('/api/auth/');
  }

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
