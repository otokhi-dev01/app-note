import 'package:get/get.dart';
import 'storage_service.dart';

class AuthService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();
  
  final _isLoggedIn = false.obs;
  bool get isLoggedIn => _isLoggedIn.value;

  Future<AuthService> init() async {
    _checkLoginStatus();
    return this;
  }

  void _checkLoginStatus() {
    _isLoggedIn.value = _storage.token != null;
  }

  void login(String token) {
    _storage.token = token;
    _isLoggedIn.value = true;
  }

  void logout() {
    _storage.clear();
    _isLoggedIn.value = false;
    Get.offAllNamed('/login');
  }
}
