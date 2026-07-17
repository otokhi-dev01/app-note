import 'package:image_picker/image_picker.dart';

abstract interface class NoteImagePicker {
  Future<XFile?> pickImage({required ImageSource source, int? imageQuality});
}

final class SystemNoteImagePicker implements NoteImagePicker {
  SystemNoteImagePicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<XFile?> pickImage({required ImageSource source, int? imageQuality}) {
    return _picker.pickImage(source: source, imageQuality: imageQuality);
  }
}
