import 'dart:convert';

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

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          debugPrint("--> ${options.method} ${options.uri}");
        }
        final token = _storage.read('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint("<-- ${response.statusCode} ${response.requestOptions.uri}");
        }
        return handler.next(response);
      },
      onError: (e, handler) {
        if (kDebugMode) {
          debugPrint("<-- ERROR ${e.response?.statusCode} ${e.requestOptions.uri}");
          _printErrorResponse(e.response?.data);
        }
        if (e.response?.statusCode == 401) {
          _storage.remove('token');
          Get.offAllNamed('/login');
        }
        return handler.next(e);
      },
    ));
  }

  void _printErrorResponse(Object? data) {
    if (!kDebugMode || data == null) return;
    final String text = data.toString();
    const int maxLength = 1000;
    debugPrint(
      text.length > maxLength ? '${text.substring(0, maxLength)}... [truncated]' : text,
    );
  }
}
