import 'package:get/get.dart';
import 'note_controller.dart';

class NoteBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NoteController());
  }
}
