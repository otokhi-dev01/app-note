import 'package:get/get.dart';
import '../controllers/recently_deleted_controller.dart';

class RecentlyDeletedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RecentlyDeletedController());
  }
}
