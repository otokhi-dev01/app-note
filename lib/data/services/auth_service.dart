import 'package:get/get.dart';
import '../models/user_model.dart';
import 'local_storage.dart';

class AuthService extends GetxService {
  final _user = Rxn<UserModel>();
  UserModel? get user => _user.value;
  bool get isLoggedIn => _user.value != null;

  Future<AuthService> init() async {
    // Check local storage for token and fetch user profile if exists
    return this;
  }

  Future<bool> login(String email, String password) async {
    try {
      // Simulate short delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      _user.value = UserModel(
        id: "1",
        email: email.isNotEmpty ? email : "user@example.com",
        name: "iOS User",
        token: "static_token",
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _user.value = UserModel(
        id: "2",
        email: email,
        name: name,
        token: "static_token",
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  void logout() {
    _user.value = null;
    Get.find<LocalStorage>().clear();
  }
}
