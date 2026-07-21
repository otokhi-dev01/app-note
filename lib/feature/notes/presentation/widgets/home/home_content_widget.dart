import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../folders/domain/entities/folder_entity.dart';
import '../../../domain/entities/note_entity.dart';
import '../../controllers/home_controller.dart';
import 'home_states_widget.dart';
import 'liquid_note_card_widget.dart';

class HomeContent extends GetView<HomeController> {
  final VoidCallback onCreateFolder;
  final VoidCallback onCreateNote;

  const HomeContent({
    super.key,
    required this.onCreateFolder,
    required this.onCreateNote,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isInitialLoading) {
        return const HomeLoadingState();
      }

      if (controller.hasFolderError &&
          controller.folders.isEmpty) {
        return _errorScrollView(
          title: 'Folders are unavailable',
          message:
          controller.folderErrorMessage.value,
          onRetry: controller.loadFolders,
        );
      }

      if (controller.hasNoteError) {
        return _errorScrollView(
          title: 'Notes are unavailable',
          message: _cleanNoteServerMessage(
            controller.noteErrorMessage.value,
          ),
          onRetry: controller.loadNotes,
        );
      }

      final List<NoteEntity> notes =
          controller.visibleNotes;

      if (notes.isEmpty) {
        return RefreshIndicator.adaptive(
          onRefresh: controller.loadAll,
          child: CustomScrollView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: HomeEmptyNotesState(
                  hasFolders:
                  controller.folders.isNotEmpty,
                  onCreateFolder:
                  onCreateFolder,
                  onCreateNote: onCreateNote,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator.adaptive(
        onRefresh: controller.loadAll,
        child: CustomScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                130,
              ),
              sliver: SliverList(
                delegate:
                SliverChildBuilderDelegate(
                      (
                      BuildContext context,
                      int index,
                      ) {
                    final NoteEntity note =
                    notes[index];

                    return Padding(
                      padding:
                      const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: LiquidNoteCard(
                        note: note,
                        folderName:
                        _folderNameFor(
                          note,
                        ),
                        onTap: () {
                          controller
                              .openNote(note.id);
                        },
                        onTogglePin: () {
                          controller
                              .togglePin(note);
                        },
                        onArchive: () {
                          controller
                              .archiveNote(note);
                        },
                        onLock: () {
                          controller
                              .lockNote(note);
                        },
                      ),
                    );
                  },
                  childCount: notes.length,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _errorScrollView({
    required String title,
    required String message,
    required Future<void> Function() onRetry,
  }) {
    return RefreshIndicator.adaptive(
      onRefresh: onRetry,
      child: CustomScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                30,
                20,
                130,
              ),
              child: HomeServerErrorState(
                title: title,
                message: message,
                onRetry: onRetry,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _folderNameFor(NoteEntity note) {
    for (final FolderEntity folder
    in controller.folders) {
      if (folder.id == note.folderId) {
        final String name =
        folder.name.trim();

        return name.isEmpty
            ? 'Unnamed Folder'
            : name;
      }
    }

    final String responseFolderName =
    note.folderName.trim();

    return responseFolderName.isEmpty
        ? 'Notes'
        : responseFolderName;
  }

  String _cleanNoteServerMessage(
      String message,
      ) {
    if (message.contains('PlainText') ||
        message.contains('PreviewText')) {
      return 'The backend note database is '
          'missing required PlainText and '
          'PreviewText columns. The backend '
          'developer must update the database '
          'or correct the note query.';
    }

    return message;
  }
}
