import 'package:flutter_test/flutter_test.dart';

import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/presentation/widgets/note_video_attachment.dart';

void main() {
  group('looksLikeVideoAttachment', () {
    test('recognizes videos from the display name', () {
      const block = AttachmentBlock(id: 'video-1', displayName: 'Holiday.MOV');

      expect(looksLikeVideoAttachment(block), isTrue);
    });

    test('recognizes videos from a remote URL with a query string', () {
      const block = AttachmentBlock(
        id: 'video-2',
        displayName: 'Attachment',
        url: 'https://example.com/uploads/clip.mp4?token=abc',
      );

      expect(looksLikeVideoAttachment(block), isTrue);
    });

    test('does not classify images and documents as videos', () {
      const image = AttachmentBlock(id: 'image-1', displayName: 'photo.jpg');
      const document = AttachmentBlock(
        id: 'document-1',
        displayName: 'notes.pdf',
      );

      expect(looksLikeVideoAttachment(image), isFalse);
      expect(looksLikeVideoAttachment(document), isFalse);
    });
  });
}
