import 'package:get/get.dart';
import 'home_controller.dart';
import '../folder/folder_controller.dart';
import 'package:otokhi_note/modules/note/note_list_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeController());
    Get.put(FolderController());
    Get.put(NoteListController());
  }
}
