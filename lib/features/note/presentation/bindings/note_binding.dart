import 'package:get/get.dart';

import 'package:Note/features/folder/domain/usecases/folder_usecases.dart';
import 'package:Note/features/note/domain/usecases/note_usecases.dart';
import 'package:Note/features/note/presentation/controllers/note_controller.dart';
import 'package:Note/features/note/presentation/controllers/note_detail_controller.dart';

class NoteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => NoteController(
        getNotes: Get.find<GetNotes>(),
        updateNoteState: Get.find<UpdateNoteState>(),
        deleteRestoreNote: Get.find<DeleteRestoreNote>(),
        moveNotes: Get.find<MoveNotesToFolder>(),
        getFolders: Get.find<GetFolders>(),
      ),
    );
    Get.lazyPut(
      () => NoteDetailController(
        getNoteDetail: Get.find<GetNoteDetail>(),
        saveNoteMetadata: Get.find<SaveNoteMetadata>(),
        saveNoteContent: Get.find<SaveNoteContent>(),
        updateNoteState: Get.find<UpdateNoteState>(),
        deleteRestoreNote: Get.find<DeleteRestoreNote>(),
        uploadAttachment: Get.find<UploadAttachment>(),
        downloadAttachment: Get.find<DownloadAttachment>(),
        getFolders: Get.find<GetFolders>(),
      ),
      fenix: true,
    );
  }
}
