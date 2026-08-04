import 'package:get/get.dart';
import 'note_controller.dart';
import 'note_detail_controller.dart';

class NoteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => NoteController());
    Get.lazyPut(() => NoteDetailController(), fenix: true);
  }
}
