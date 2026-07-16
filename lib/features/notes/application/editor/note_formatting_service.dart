/// A framework-independent text value used by [NoteFormattingService].
class NoteFormattingValue {
  const NoteFormattingValue({
    required this.text,
    required this.selectionStart,
    required this.selectionEnd,
  });

  final String text;
  final int selectionStart;
  final int selectionEnd;
}

/// Applies deterministic note-editor text mutations.
///
/// Invalid selections collapse to the end of the input, matching the editor's
/// previous defensive selection behavior.
class NoteFormattingService {
  const NoteFormattingService();

  static const _checkbox = '☐ ';
  static const _table =
      '| Category | Task | Status |\n'
      '| --- | --- | --- |\n'
      '| Personal | Morning run | Completed |\n'
      '| Work | Project review | Pending |\n';

  NoteFormattingValue toggleChecklist(NoteFormattingValue value) {
    final selection = _safeSelection(value);
    return _replaceAndCollapse(value.text, selection, _checkbox);
  }

  NoteFormattingValue addTag(NoteFormattingValue value, String tag) {
    final selection = _safeSelection(value);
    return _replaceAndCollapse(value.text, selection, '$tag ');
  }

  NoteFormattingValue applyInlineFormat(
    NoteFormattingValue value, {
    required String prefix,
    required String suffix,
  }) {
    final selection = _safeSelection(value);
    final selected = value.text.substring(selection.start, selection.end);
    final replacement = '$prefix$selected$suffix';
    return NoteFormattingValue(
      text: value.text.replaceRange(
        selection.start,
        selection.end,
        replacement,
      ),
      selectionStart: selection.start + prefix.length,
      selectionEnd: selection.start + prefix.length + selected.length,
    );
  }

  NoteFormattingValue applyLineFormat(
    NoteFormattingValue value,
    String prefix,
  ) {
    final selection = _safeSelection(value);
    final lineStart = selection.start == 0
        ? 0
        : value.text.lastIndexOf('\n', selection.start - 1) + 1;
    return NoteFormattingValue(
      text: value.text.replaceRange(lineStart, lineStart, prefix),
      selectionStart: selection.end + prefix.length,
      selectionEnd: selection.end + prefix.length,
    );
  }

  NoteFormattingValue insertTable(NoteFormattingValue value) {
    final selection = _safeSelection(value);
    final prefix =
        selection.start > 0 && value.text[selection.start - 1] != '\n'
        ? '\n\n'
        : '';
    return _replaceAndCollapse(value.text, selection, '$prefix$_table');
  }

  NoteFormattingValue _replaceAndCollapse(
    String text,
    ({int start, int end}) selection,
    String replacement,
  ) {
    final offset = selection.start + replacement.length;
    return NoteFormattingValue(
      text: text.replaceRange(selection.start, selection.end, replacement),
      selectionStart: offset,
      selectionEnd: offset,
    );
  }

  ({int start, int end}) _safeSelection(NoteFormattingValue value) {
    final start = value.selectionStart;
    final end = value.selectionEnd;
    if (start < 0 || end < start || end > value.text.length) {
      return (start: value.text.length, end: value.text.length);
    }
    return (start: start, end: end);
  }
}
