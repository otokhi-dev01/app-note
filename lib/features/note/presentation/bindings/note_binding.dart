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
    // Tagged per push (see NoteNavigation._newInstanceTag): NOTE_DETAIL can be
    // stacked on top of itself — opening a note, or starting a new one, from
    // inside an already-open note — and without a unique tag GetX would hand
    // back that still-alive note's singleton controller instead of building a
    // fresh one for the new page.
    final args = Get.arguments;
    final tag = args is Map ? args['instanceTag']?.toString() : null;
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
      tag: tag,
      fenix: true,
    );
  }
}
