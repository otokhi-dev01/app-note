import 'package:get/get.dart';
import '../../core/network/api_client.dart';

class ApiService extends GetxService {
  late ApiClient client;

  Future<ApiService> init() async {
    client = ApiClient();
    return this;
  }
}
