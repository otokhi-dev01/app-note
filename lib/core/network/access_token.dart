/// The raw access token and safe metadata about its input formatting.
///
/// Normalization never decodes, re-encodes, or otherwise changes JWT bytes.
/// Signature validation belongs to the server.
class AccessToken {
  const AccessToken._({
    required this.value,
    required this.bearerPrefixRemoved,
    required this.duplicateBearerPrefix,
    required this.hadWhitespace,
  });

  final String value;
  final bool bearerPrefixRemoved;
  final bool duplicateBearerPrefix;
  final bool hadWhitespace;

  static final _bearerPrefix = RegExp(
    r'^bearer(?:\s+|$)',
    caseSensitive: false,
  );
  static final _whitespace = RegExp(r'\s');

  static AccessToken normalize(String? value) {
    final input = value ?? '';
    var raw = input.trim();
    var prefixes = 0;
    while (true) {
      final prefix = _bearerPrefix.firstMatch(raw);
      if (prefix == null) break;
      raw = raw.substring(prefix.end).trim();
      prefixes++;
    }
    return AccessToken._(
      value: raw,
      bearerPrefixRemoved: prefixes > 0,
      duplicateBearerPrefix: prefixes > 1,
      hadWhitespace: input != input.trim() || _whitespace.hasMatch(raw),
    );
  }
}
