import 'dart:io';

import 'package:notes/features/library/application/attachment_size_query.dart';
import 'package:notes/features/notes/domain/entities/note.dart';

final class LocalAttachmentSizeQuery implements AttachmentSizeQuery {
  const LocalAttachmentSizeQuery();

  @override
  Future<int> calculate(List<Note> notes) async {
    var total = 0;
    for (final path in notes.expand((note) => note.imagePaths)) {
      try {
        total += await File(path).length();
      } catch (_) {
        // Missing local files do not count toward current storage usage.
      }
    }
    return total;
  }
}
