import 'dart:convert';

import 'package:Note/core/network/access_token.dart';

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
      ..._tokenDetails(authorization, now: now),
    };
    details['serverReason'] = serverReason(challenges);
    return jsonEncode(details);
  }

  static String serverReason(Iterable<String> challenges) {
    final challenge = challenges.join(' ').toLowerCase();
    // Classify the server challenge instead of printing it: some servers echo
    // credentials or user identifiers in their error descriptions.
    return switch (challenge) {
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
  }

  /// Safe metadata for token storage/restore, including formatting repairs.
  static String describeToken(String? value, {DateTime? now}) =>
      jsonEncode(_tokenDetails(value, now: now));

  static Map<String, Object?> _tokenDetails(String? value, {DateTime? now}) {
    final normalized = AccessToken.normalize(value);
    final token = normalized.value;
    final parts = token.split('.');
    final header = parts.length == 3 ? _object(parts[0]) : null;
    final payload = parts.length == 3 ? _object(parts[1]) : null;
    final algorithm = header?['alg'];
    final malformed =
        token.isNotEmpty &&
        (parts.length != 3 ||
            header == null ||
            algorithm is! String ||
            algorithm.isEmpty ||
            payload == null ||
            !_validSegment(parts[2]));
    final details = <String, Object?>{
      'tokenExists': token.isNotEmpty,
      'tokenLength': token.length,
      'tokenHasWhitespace': normalized.hadWhitespace,
      'bearerPrefixRemoved': normalized.bearerPrefixRemoved,
      'duplicateBearerPrefix': normalized.duplicateBearerPrefix,
      'malformedToken': malformed,
      'jwtPayloadReadable': payload != null,
    };
    if (payload != null) {
      // Only issuer/audience and validity state: never log credentials, user
      // claims, signatures, or arbitrary fields. Claims are untrusted input.
      details['issuer'] = _label(payload['iss']);
      final audience = payload['aud'];
      details['audience'] = audience is List
          ? audience.take(4).map(_label).toList()
          : _label(audience);
      final seconds = (now ?? DateTime.now()).millisecondsSinceEpoch / 1000;
      final expiry = payload['exp'];
      final notBefore = payload['nbf'];
      details['expiredAtDeviceTime'] = expiry is num ? seconds >= expiry : null;
      details['notYetValidAtDeviceTime'] = notBefore is num
          ? seconds < notBefore
          : null;
    }
    details['tokenState'] = token.isEmpty
        ? 'missing'
        : malformed
        ? 'malformed'
        : details['expiredAtDeviceTime'] == true
        ? 'expired'
        : details['notYetValidAtDeviceTime'] == true
        ? 'not_yet_valid'
        : 'present';
    return details;
  }

  static final _base64UrlSegment = RegExp(r'^[A-Za-z0-9_-]+={0,2}$');
  static final _jwtInClaim = RegExp(
    r'[A-Za-z0-9_-]+={0,2}\.[A-Za-z0-9_-]+={0,2}\.[A-Za-z0-9_-]+={0,2}',
  );

  static bool _validSegment(String value) {
    if (!_base64UrlSegment.hasMatch(value)) return false;
    try {
      return base64Url.decode(base64Url.normalize(value)).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic>? _object(String segment) {
    if (!_base64UrlSegment.hasMatch(segment)) return null;
    try {
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(segment))),
      );
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      // Malformed diagnostics must never hide the original HTTP error.
      return null;
    }
  }

  static String? _label(Object? value) {
    if (value is! String) return null;
    if (value.length > 120) return '[oversized claim]';
    if (RegExp(r'[\x00-\x1f\x7f]').hasMatch(value)) return '[redacted claim]';
    // A server can echo another JWT in an issuer/audience claim. Preserve
    // ordinary issuer URLs while withholding anything with a JWT header.
    for (final match in _jwtInClaim.allMatches(value)) {
      final header = match.group(0)!.split('.').first;
      for (var offset = 0; offset < header.length; offset++) {
        if (_object(header.substring(offset)) != null) {
          return '[redacted claim]';
        }
      }
    }
    return value;
  }
}
