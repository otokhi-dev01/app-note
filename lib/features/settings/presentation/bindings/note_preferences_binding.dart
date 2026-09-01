import 'package:get/get.dart';
import 'package:Note/features/settings/presentation/controllers/note_preferences_controller.dart';

class NotePreferencesBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NotePreferencesController());
  }
}
