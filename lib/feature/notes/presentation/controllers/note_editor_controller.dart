import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import 'home_controller.dart';

class NoteEditorController extends GetxController {
  final NoteRepository noteRepository;
  final HomeController? homeController;

  NoteEditorController({
    required this.noteRepository,
    this.homeController,
  });

  final TextEditingController titleController =
  TextEditingController();

  final TextEditingController statementController =
  TextEditingController();

  final Rxn<NoteEntity> note =
  Rxn<NoteEntity>();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  final RxString errorMessage = ''.obs;

  late final int noteId;

  @override
  void onInit() {
    super.onInit();

    noteId = _readNoteId();

    /*
     * GET NOTE DETAIL METHOD IS CALLED HERE.
     */
    getNoteDetail();
  }

  int _readNoteId() {
    final dynamic arguments =
        Get.arguments;

    /*
     * Supports:
     *
     * Get.toNamed(
     *   AppRoutes.noteEditor,
     *   arguments: 10,
     * );
     */
    if (arguments is int &&
        arguments > 0) {
      return arguments;
    }

    /*
     * Supports:
     *
     * Get.toNamed(
     *   AppRoutes.noteEditor,
     *   arguments: {
     *     'noteId': 10,
     *   },
     * );
     */
    if (arguments is Map) {
      final dynamic value =
          arguments['noteId'] ??
              arguments['id'];

      final int? parsedId =
      int.tryParse(
        value?.toString() ?? '',
      );

      if (parsedId != null &&
          parsedId > 0) {
        return parsedId;
      }
    }

    throw ArgumentError(
      'A valid note ID was not provided.',
    );
  }

  /*
   * This method loads:
   *
   * GET /api/note/{id}
   */
  Future<void> getNoteDetail() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final NoteEntity result =
      await noteRepository.getNoteDetail(
        noteId,
      );

      note.value = result;

      titleController.text =
          result.title;

      statementController.text =
          _extractTextContent(
            result.content,
          );
    } catch (error) {
      errorMessage.value =
          _cleanError(error);
    } finally {
      isLoading.value = false;
    }
  }

  /*
   * Refresh method for pull-to-refresh or retry.
   */
  Future<void> reloadNote() {
    return getNoteDetail();
  }

  /*
   * Save edited title and statement.
   *
   * Existing attachment blocks are preserved.
   */
  Future<void> saveChanges() async {
    FocusManager.instance.primaryFocus
        ?.unfocus();

    final String title =
    titleController.text.trim();

    final String statement =
    statementController.text.trim();

    if (title.isEmpty) {
      errorMessage.value =
      'Please enter a note title.';
      return;
    }

    if (title.length > 250) {
      errorMessage.value =
      'The note title cannot exceed 250 characters.';
      return;
    }

    try {
      isSaving.value = true;
      errorMessage.value = '';

      final List<Map<String, dynamic>>
      updatedContent =
      _buildUpdatedContent(
        statement: statement,
      );

      await noteRepository.saveContent(
        id: noteId,
        title: title,
        content: updatedContent,
      );

      /*
       * Reload from the server after saving.
       */
      await getNoteDetail();

      if (homeController != null) {
        await homeController!.loadAll();
      }

      Get.snackbar(
        'Note saved',
        'Your changes were saved successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      errorMessage.value =
          _cleanError(error);
    } finally {
      isSaving.value = false;
    }
  }

  List<Map<String, dynamic>>
  _buildUpdatedContent({
    required String statement,
  }) {
    final List<Map<String, dynamic>>
    originalContent =
        note.value?.content
            .map(
              (
              Map<String, dynamic>
              block,
              ) {
            return Map<String, dynamic>.from(
              block,
            );
          },
        )
            .toList() ??
            <Map<String, dynamic>>[];

    /*
     * Find the old text block so its ID can remain stable.
     */
    Map<String, dynamic>? oldTextBlock;

    for (final Map<String, dynamic> block
    in originalContent) {
      final String type =
          block['type']
              ?.toString()
              .trim()
              .toLowerCase() ??
              '';

      if (type == 'text') {
        oldTextBlock = block;
        break;
      }
    }

    /*
     * Keep all non-text blocks such as images
     * and attachments.
     */
    final List<Map<String, dynamic>>
    nonTextBlocks =
    originalContent.where(
          (Map<String, dynamic> block) {
        final String type =
            block['type']
                ?.toString()
                .trim()
                .toLowerCase() ??
                '';

        return type != 'text';
      },
    ).map(
          (Map<String, dynamic> block) {
        return Map<String, dynamic>.from(
          block,
        );
      },
    ).toList();

    final List<Map<String, dynamic>> result =
    <Map<String, dynamic>>[];

    if (statement.isNotEmpty) {
      final String textBlockId =
          oldTextBlock?['id']?.toString() ??
              'text-$noteId';

      final String blockId =
          oldTextBlock?['blockId']
              ?.toString() ??
              textBlockId;

      result.add(
        <String, dynamic>{
          ...?oldTextBlock,
          'id': textBlockId,
          'blockId': blockId,
          'type': 'text',
          'text': statement,
          'displayOrder': 1,
        },
      );
    }

    result.addAll(nonTextBlocks);

    /*
     * Reassign display order after updating content.
     */
    for (
    int index = 0;
    index < result.length;
    index++
    ) {
      result[index]['displayOrder'] =
          index + 1;
    }

    return result;
  }

  String _extractTextContent(
      List<Map<String, dynamic>> content,
      ) {
    for (final Map<String, dynamic> block
    in content) {
      final String type =
          block['type']
              ?.toString()
              .trim()
              .toLowerCase() ??
              '';

      if (type == 'text') {
        return block['text']
            ?.toString() ??
            '';
      }
    }

    return '';
  }

  String _cleanError(
      Object error,
      ) {
    return error
        .toString()
        .replaceFirst(
      'ApiException: ',
      '',
    )
        .replaceFirst(
      'Exception: ',
      '',
    )
        .trim();
  }

  @override
  void onClose() {
    titleController.dispose();
    statementController.dispose();

    super.onClose();
  }
}