import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import '../../app/services/api_service.dart';

abstract class ApiProvider {
  final ApiService apiService = Get.find<ApiService>();

  Future<dio.Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await apiService.client.dio.get(path, queryParameters: queryParameters);
  }

  Future<dio.Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await apiService.client.dio.post(path, data: data, queryParameters: queryParameters);
  }

  Future<dio.Response> delete(String path, {dynamic data}) async {
    return await apiService.client.dio.delete(path, data: data);
  }

  Future<dio.Response> put(String path, {dynamic data}) async {
    return await apiService.client.dio.put(path, data: data);
  }
}
