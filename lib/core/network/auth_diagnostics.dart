import 'dart:convert';

/// Debug metadata only. Decoding a JWT does not verify its signature or grant
/// access; the server remains responsible for authentication.
class AuthDiagnostics {
  AuthDiagnostics._();

  static String describe({
    required String? authorization,
    Iterable<String> challenges = const [],
    DateTime? now,
  }) {
    final details = <String, Object?>{
      'authorizationAttached': authorization != null,
    };
    final token = authorization?.startsWith('Bearer ') == true
        ? authorization!.substring(7)
        : '';
    details['tokenHasWhitespace'] = token != token.trim();
    details['duplicateBearerPrefix'] = token.toLowerCase().startsWith(
      'bearer ',
    );
    final parts = token.split('.');
    details['jwtPayloadReadable'] = false;
    if (parts.length == 3) {
      try {
        final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );
        if (payload is Map) {
          details['jwtPayloadReadable'] = true;
          // Only issuer/audience and validity state: never log the token,
          // signature, subject, session ID, email, or arbitrary payload fields.
          details['issuer'] = _label(payload['iss']);
          final audience = payload['aud'];
          details['audience'] = audience is List
              ? audience.take(4).map(_label).toList()
              : _label(audience);
          final seconds = (now ?? DateTime.now()).millisecondsSinceEpoch / 1000;
          final expiry = payload['exp'];
          final notBefore = payload['nbf'];
          details['expiredAtDeviceTime'] = expiry is num
              ? seconds >= expiry
              : null;
          details['notYetValidAtDeviceTime'] = notBefore is num
              ? seconds < notBefore
              : null;
        }
      } catch (_) {
        // Malformed diagnostics must never hide the original HTTP error.
      }
    }
    final challenge = challenges.join(' ').toLowerCase();
    // Classify the server challenge instead of printing it: some servers echo
    // credentials or user identifiers in their error descriptions.
    details['serverReason'] = switch (challenge) {
      final value when value.contains('issuer') => 'issuer_rejected',
      final value when value.contains('audience') => 'audience_rejected',
      final value
          when value.contains('signature') || value.contains('signing key') =>
        'signature_rejected',
      final value when value.contains('expired') => 'expired',
      final value when value.contains('not yet valid') => 'not_yet_valid',
      final value when value.contains('invalid_token') => 'invalid_token',
      '' => 'challenge_absent',
      _ => 'unspecified',
    };
    return jsonEncode(details);
  }

  static String? _label(Object? value) {
    if (value is! String) return null;
    return value.length <= 120 ? value : '[oversized claim]';
  }
}
