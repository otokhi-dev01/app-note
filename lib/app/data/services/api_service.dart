import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';

class ApiService extends GetxService {
  late Dio _dio;
  final _storage = GetStorage();
  
  // Base URL for  Note API
  static const String baseUrl = "https://note.piisiit.com"; 

  Dio get dio => _dio;

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true, // Re-enable for debugging trash items
      logPrint: (obj) => debugPrint(obj.toString()),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _storage.read('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        if (e.response?.statusCode == 401) {
          // Handle Unauthorized - Clear token and redirect to login
          _storage.remove('token');
          Get.offAllNamed('/login');
        }
        return handler.next(e);
      },
    ));
  }
}
