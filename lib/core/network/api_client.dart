import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'api_parser.dart';

class ApiClient {
  final TokenStorage tokenStorage;
  final Dio _dio;

  ApiClient({
    required this.tokenStorage,
    Dio? dio,
  }) : _dio = dio ??
      Dio(
        BaseOptions(
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          sendTimeout: ApiConfig.sendTimeout,
          responseType: ResponseType.json,
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

  Future<dynamic> get(
      String path, {
        bool requiresAuth = true,
        bool useAuthBaseUrl = false,
        Map<String, dynamic>? queryParameters,
      }) async {
    return _request(
          () async {
        return _dio.get<dynamic>(
          _buildUrl(
            path,
            useAuthBaseUrl: useAuthBaseUrl,
          ),
          queryParameters: queryParameters,
          options: Options(
            headers: await _createHeaders(
              requiresAuth: requiresAuth,
            ),
          ),
        );
      },
    );
  }

  Future<dynamic> post(
      String path, {
        dynamic body,
        bool requiresAuth = true,
        bool useAuthBaseUrl = false,
      }) async {
    final dynamic requestBody = body ?? <String, dynamic>{};

    return _request(
          () async {
        return _dio.post<dynamic>(
          _buildUrl(
            path,
            useAuthBaseUrl: useAuthBaseUrl,
          ),
          data: requestBody,
          options: Options(
            contentType: requestBody is FormData
                ? null
                : Headers.jsonContentType,
            headers: await _createHeaders(
              requiresAuth: requiresAuth,
            ),
          ),
        );
      },
    );
  }

  Future<dynamic> uploadFile(
      String path, {
        required String filePath,
        required String fileName,
        required Map<String, dynamic> fields,
      }) async {
    final FormData formData = FormData.fromMap({
      ...fields,
      'File': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });

    return _request(
          () async {
        return _dio.post<dynamic>(
          _buildUrl(path),
          data: formData,
          options: Options(
            headers: await _createHeaders(
              requiresAuth: true,
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _createHeaders({
    required bool requiresAuth,
  }) async {
    final Map<String, dynamic> headers = {
      'Accept': 'application/json',
    };

    if (!requiresAuth) {
      return headers;
    }

    final String? token = await tokenStorage.readToken();

    if (token == null || token.trim().isEmpty) {
      throw const ApiException(
        message: 'Authentication token is missing.',
        statusCode: 401,
      );
    }

    headers['Authorization'] = 'Bearer $token';

    return headers;
  }

  String _buildUrl(
      String path, {
        bool useAuthBaseUrl = false,
      }) {
    String baseUrl = useAuthBaseUrl
        ? ApiConfig.authBaseUrl
        : ApiConfig.apiBaseUrl;

    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(
        0,
        baseUrl.length - 1,
      );
    }

    final String normalizedPath =
    path.startsWith('/') ? path : '/$path';

    return '$baseUrl$normalizedPath';
  }

  Future<dynamic> _request(
      Future<Response<dynamic>> Function() action,
      ) async {
    try {
      final Response<dynamic> response = await action();

      final int statusCode = response.statusCode ?? 0;

      if (statusCode >= 200 && statusCode < 300) {
        try {
          ApiParser.ensureSuccess(response.data);
        } on ApiException catch (error) {
          if (error.isUnauthorized) {
            await tokenStorage.deleteToken();
          }

          rethrow;
        }

        return response.data;
      }

      if (statusCode == 401) {
        await tokenStorage.deleteToken();
      }

      throw ApiException(
        message: _extractMessage(response.data),
        statusCode: statusCode,
        responseData: response.data,
      );
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      final Response<dynamic>? response = error.response;

      if (response != null) {
        if (response.statusCode == 401) {
          await tokenStorage.deleteToken();
        }

        throw ApiException(
          message: _extractMessage(response.data),
          statusCode: response.statusCode,
          responseData: response.data,
        );
      }

      throw ApiException(
        message: error.message ?? 'Network request failed.',
      );
    } catch (error) {
      throw ApiException(
        message: 'Unexpected error: $error',
      );
    }
  }

  String _extractMessage(dynamic responseData) {
    return ApiParser.responseMessage(
      responseData,
      fallback: 'Request failed.',
    );
  }
}
