import 'package:flutter_test/flutter_test.dart';
import 'package:Note/features/folder/domain/folder_default_name.dart';

void main() {
  group('nextDefaultFolderName', () {
    test('starts numbering at one', () {
      expect(nextDefaultFolderName(const []), 'New Folder 1');
    });

    test('increments after the highest existing number', () {
      expect(
        nextDefaultFolderName(const [
          'New Folder 1',
          'New Folder 3',
          'New Folder 2',
        ]),
        'New Folder 4',
      );
    });

    test('matches case-insensitively and ignores unrelated names', () {
      expect(
        nextDefaultFolderName(const [
          'Work',
          'New Folder',
          'new folder 7',
          'New Folder draft',
        ]),
        'New Folder 8',
      );
    });
  });
}
