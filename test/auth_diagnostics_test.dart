import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:Note/core/network/auth_diagnostics.dart';

String token(Map<String, Object> claims) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode(claims)))}.private-signature';

void main() {
  test('Reports relevant JWT metadata without credentials or user claims', () {
    final jwt = token({
      'iss': 'ChatApi',
      'aud': ['NoteClient'],
      'exp': 2000,
      'nbf': 1000,
      'sub': 'private-user',
      'sid': 'private-session',
      'email': 'private@example.com',
    });
    final output = AuthDiagnostics.describe(
      authorization: 'Bearer $jwt',
      challenges: [
        'Bearer error="invalid_token", error_description="The issuer was rejected: $jwt"',
      ],
      now: DateTime.fromMillisecondsSinceEpoch(1500000, isUtc: true),
    );
    final details = jsonDecode(output);
    expect(details['issuer'], 'ChatApi');
    expect(details['audience'], ['NoteClient']);
    expect(details['expiredAtDeviceTime'], isFalse);
    expect(details['notYetValidAtDeviceTime'], isFalse);
    expect(details['serverReason'], 'issuer_rejected');
    for (final secret in [
      jwt,
      'private-user',
      'private-session',
      'private@example.com',
      'private-signature',
    ]) {
      expect(output, isNot(contains(secret)));
    }
  });

  test('Separates formatting failures from JWT rejection without throwing', () {
    for (final value in [null, 'Bearer short', 'Bearer a.%%%%.c']) {
      final details = jsonDecode(
        AuthDiagnostics.describe(authorization: value),
      );
      expect(details['jwtPayloadReadable'], isFalse);
      expect(details['serverReason'], 'challenge_absent');
    }
    final duplicate = jsonDecode(
      AuthDiagnostics.describe(authorization: 'Bearer Bearer value '),
    );
    expect(duplicate['duplicateBearerPrefix'], isTrue);
    expect(duplicate['tokenHasWhitespace'], isTrue);
  });

  test(
    'Labels device clock comparisons without treating them as validation',
    () {
      final details = jsonDecode(
        AuthDiagnostics.describe(
          authorization: 'Bearer ${token({'exp': 1000, 'nbf': 2000})}',
          now: DateTime.fromMillisecondsSinceEpoch(1500000, isUtc: true),
        ),
      );
      expect(details['expiredAtDeviceTime'], isTrue);
      expect(details['notYetValidAtDeviceTime'], isTrue);
    },
  );

  test('Classifies server errors without logging raw descriptions', () {
    for (final entry in {
      'invalid audience': 'audience_rejected',
      'signature validation failed': 'signature_rejected',
      'token expired': 'expired',
      'token is not yet valid': 'not_yet_valid',
      'Bearer error="invalid_token"': 'invalid_token',
      'Bearer': 'unspecified',
    }.entries) {
      final details = jsonDecode(
        AuthDiagnostics.describe(authorization: null, challenges: [entry.key]),
      );
      expect(details['serverReason'], entry.value);
    }
  });
}
