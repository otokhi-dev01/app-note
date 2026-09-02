import 'package:flutter_test/flutter_test.dart';

import 'package:Note/core/utils/media_title.dart';

void main() {
  group('media titles', () {
    test('shows the file name without its extension', () {
      expect(
        mediaTitleFromDisplayName('Summer holiday.MOV', fallback: 'Video'),
        'Summer holiday',
      );
    });

    test('uses a friendly fallback for generated picker names', () {
      expect(
        mediaTitleFromDisplayName('image_picker_47A1.png', fallback: 'Image'),
        'Image',
      );
    });

    test('renames a title while preserving the media extension', () {
      expect(
        displayNameWithMediaTitle(
          title: 'Family trip',
          currentDisplayName: 'IMG_1001.JPG',
        ),
        'Family trip.JPG',
      );
    });

    test('uses the local path extension when the display name has none', () {
      expect(
        displayNameWithMediaTitle(
          title: 'My sketch',
          currentDisplayName: 'Sketch',
          localPath: '/documents/sketch.png',
        ),
        'My sketch.png',
      );
    });

    test('does not duplicate an extension entered by the user', () {
      expect(
        displayNameWithMediaTitle(
          title: 'Proposal.pdf',
          currentDisplayName: 'document.pdf',
        ),
        'Proposal.pdf',
      );
    });
  });
}
