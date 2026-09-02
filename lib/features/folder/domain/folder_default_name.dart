const defaultFolderName = 'New Folder';

/// Returns the next numbered default folder name after the highest one in
/// [existingNames]. Names that do not match `New Folder <number>` are ignored.
String nextDefaultFolderName(Iterable<String> existingNames) {
  final numberedDefault = RegExp(
    '^${RegExp.escape(defaultFolderName)}\\s+(\\d+)\$',
    caseSensitive: false,
  );
  var highestNumber = 0;

  for (final name in existingNames) {
    final match = numberedDefault.firstMatch(name.trim());
    final number = match == null ? null : int.tryParse(match.group(1)!);
    if (number != null && number > highestNumber) {
      highestNumber = number;
    }
  }

  return '$defaultFolderName ${highestNumber + 1}';
}
