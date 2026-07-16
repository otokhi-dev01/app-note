import 'package:intl/intl.dart';

abstract final class DateFormatter {
  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static String format(DateTime date) {
    return _displayFormat.format(date);
  }
}
