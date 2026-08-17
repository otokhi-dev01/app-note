/// Lenient converters for a backend that is inconsistent about types.
///
/// The API returns ids as both `int` and `String`, and booleans as `true`,
/// `"true"`, and `1`. These were duplicated as private `_toInt` / `_toString` /
/// `_toBool` helpers in three model files.
library;

int asInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

String asString(dynamic value) => value?.toString() ?? '';

bool asBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().toLowerCase();
  return text == 'true' || text == '1';
}

DateTime? asDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
