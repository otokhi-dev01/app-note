import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'api_parser.dart';

class ApiClient {
  final TokenStorage tokenStorage;
  final Dio _dio;

  ApiClient({required this.tokenStorage, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
              sendTimeout: ApiConfig.sendTimeout,
              responseType: ResponseType.json,
              headers: {'Accept': 'application/json'},
            ),
          );

  Future<dynamic> get(
    String path, {
    bool requiresAuth = true,
    bool useAuthBaseUrl = false,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _request(() async {
      return _dio.get<dynamic>(
        _buildUrl(path, useAuthBaseUrl: useAuthBaseUrl),
        queryParameters: queryParameters,
        options: Options(
          headers: await _createHeaders(requiresAuth: requiresAuth),
        ),
      );
    });
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    bool requiresAuth = true,
    bool useAuthBaseUrl = false,
  }) async {
    final dynamic requestBody = body ?? <String, dynamic>{};

    return _request(() async {
      return _dio.post<dynamic>(
        _buildUrl(path, useAuthBaseUrl: useAuthBaseUrl),
        data: requestBody,
        options: Options(
          contentType: requestBody is FormData ? null : Headers.jsonContentType,
          headers: await _createHeaders(requiresAuth: requiresAuth),
        ),
      );
    });
  }

  Future<dynamic> uploadFile(
    String path, {
    required String filePath,
    required String fileName,
    required Map<String, dynamic> fields,
  }) async {
    final FormData formData = FormData.fromMap({
      ...fields,
      'File': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    return _request(() async {
      return _dio.post<dynamic>(
        _buildUrl(path),
        data: formData,
        options: Options(headers: await _createHeaders(requiresAuth: true)),
      );
    });
  }

  Future<Map<String, dynamic>> _createHeaders({
    required bool requiresAuth,
  }) async {
    final Map<String, dynamic> headers = {'Accept': 'application/json'};

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

  String _buildUrl(String path, {bool useAuthBaseUrl = false}) {
    String baseUrl =
        (useAuthBaseUrl ? ApiConfig.authBaseUrl : ApiConfig.apiBaseUrl).trim();

    final Uri? configuredUri = Uri.tryParse(baseUrl);
    final bool hasSupportedScheme =
        configuredUri?.scheme == 'https' || configuredUri?.scheme == 'http';

    if (!hasSupportedScheme || configuredUri?.host.isEmpty != false) {
      throw const ApiException(
        message: 'The API base URL is missing or invalid.',
      );
    }

    while (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    final String normalizedPath = path.startsWith('/') ? path : '/$path';

    return '$baseUrl$normalizedPath';
  }

  Future<dynamic> _request(Future<Response<dynamic>> Function() action) async {
    try {
      final Response<dynamic> response = await action();

      final int statusCode = response.statusCode ?? 0;
      final dynamic responseData = ApiParser.decodeResponse(response.data);

      if (statusCode >= 200 && statusCode < 300) {
        try {
          ApiParser.ensureSuccess(responseData);
        } on ApiException catch (error) {
          if (error.isUnauthorized) {
            await tokenStorage.deleteToken();
          }

          rethrow;
        }

        return responseData;
      }

      if (statusCode == 401) {
        await tokenStorage.deleteToken();
      }

      throw ApiException(
        message: _extractMessage(responseData),
        statusCode: statusCode,
        responseData: responseData,
      );
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      final Response<dynamic>? response = error.response;

      if (response != null) {
        final dynamic responseData = ApiParser.decodeResponse(response.data);

        if (response.statusCode == 401) {
          await tokenStorage.deleteToken();
        }

        throw ApiException(
          message: _extractMessage(responseData),
          statusCode: response.statusCode,
          responseData: responseData,
        );
      }

      throw ApiException(message: _networkMessage(error));
    } catch (error) {
      throw ApiException(message: 'Unexpected error: $error');
    }
  }

  String _extractMessage(dynamic responseData) {
    return ApiParser.responseMessage(responseData, fallback: 'Request failed.');
  }

  String _networkMessage(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout =>
        'The connection timed out. Please check your network and try again.',
      DioExceptionType.sendTimeout =>
        'The request timed out while sending data. Please try again.',
      DioExceptionType.receiveTimeout =>
        'The server took too long to respond. Please try again.',
      DioExceptionType.transformTimeout =>
        'The server response took too long to process. Please try again.',
      DioExceptionType.connectionError =>
        'Unable to connect to the server. Please check your network.',
      DioExceptionType.badCertificate =>
        'A secure connection to the server could not be established.',
      DioExceptionType.cancel => 'The request was cancelled.',
      DioExceptionType.badResponse => 'The server rejected the request.',
      DioExceptionType.unknown =>
        error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Network request failed.',
    };
  }
}
