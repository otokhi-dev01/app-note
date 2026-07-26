import 'package:dio/dio.dart';
import 'package:get/instance_manager.dart';
import '../../app/services/storage_service.dart';
import '../constants/app_constants.dart';

class ApiClient {
  late Dio dio;
  final StorageService _storageService = Get.find<StorageService>();

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _storageService.token;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Handle global errors (e.g. 401 logout)
        if (e.response?.statusCode == 401) {
          // Trigger logout or refresh token logic
        }
        return handler.next(e);
      },
    ));
  }
}
