import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Use lazyPut with fenix: true to allow the controller to be re-initialized 
    // if it was disposed, and to share it properly between Login and Register.
    Get.lazyPut(() => AuthController(), fenix: true);
  }
}
