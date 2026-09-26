import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:Note/core/network/auth_diagnostics.dart';

String segment(Object value) =>
    base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

String token(Map<String, Object> claims) =>
    '${segment({'alg': 'HS256', 'typ': 'JWT'})}.${segment(claims)}.'
    '${base64Url.encode(utf8.encode('private-signature')).replaceAll('=', '')}';

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
    expect(details['tokenState'], 'present');
    expect(details['malformedToken'], isFalse);
    expect(details['tokenExists'], isTrue);
    expect(details['tokenLength'], jwt.length);
    for (final secret in [
      jwt,
      'private-user',
      'private-session',
      'private@example.com',
      'private-signature',
      jwt.split('.').last,
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
    expect(duplicate['bearerPrefixRemoved'], isTrue);
    expect(duplicate['tokenState'], 'malformed');
  });

  test('Distinguishes a missing token from malformed JWTs', () {
    final missing = jsonDecode(AuthDiagnostics.describeToken(null));
    expect(missing['tokenState'], 'missing');
    expect(missing['tokenExists'], isFalse);
    expect(missing['malformedToken'], isFalse);
    for (final value in [
      'opaque-token',
      'a.b.c',
      '${segment({'alg': 'HS256'})}.${segment([])}.c2ln',
      '${segment({})}.${segment({})}.c2ln',
      '${segment({'alg': 'HS256'})}.${segment({})}.%%%%',
      '${segment({'alg': 'HS256'})}.${segment({})}.',
    ]) {
      final details = jsonDecode(AuthDiagnostics.describeToken(value));
      expect(details['tokenState'], 'malformed', reason: value);
      expect(details['malformedToken'], isTrue, reason: value);
    }
  });

  test(
    'Storage diagnostics expose prefix repair metadata without token bytes',
    () {
      final jwt = token({'iss': 'PiisiitChat', 'aud': 'PiisiitClient'});
      final output = AuthDiagnostics.describeToken(' Bearer Bearer $jwt ');
      final details = jsonDecode(output);
      expect(details['bearerPrefixRemoved'], isTrue);
      expect(details['duplicateBearerPrefix'], isTrue);
      expect(details['tokenHasWhitespace'], isTrue);
      expect(details['tokenLength'], jwt.length);
      expect(details['tokenState'], 'present');
      expect(output, isNot(contains(jwt)));
    },
  );

  test('Redacts JWTs injected into issuer and audience claims', () {
    final secret = token({'sub': 'secret'});
    final jwt = token({
      'iss': secret,
      'aud': ['prefix$secret', secret],
    });
    final output = AuthDiagnostics.describeToken(jwt);
    final details = jsonDecode(output);
    expect(details['issuer'], '[redacted claim]');
    expect(details['audience'], ['[redacted claim]', '[redacted claim]']);
    expect(output, isNot(contains(secret)));
    expect(output, isNot(contains(jwt)));
  });

  test('Preserves issuer URLs and bounds untrusted diagnostic labels', () {
    final details = jsonDecode(
      AuthDiagnostics.describeToken(
        token({
          'iss': 'https://auth.piisiit.com',
          'aud': ['a' * 121, 'unsafe\nlabel', 7, 'client', 'fifth'],
        }),
      ),
    );
    expect(details['issuer'], 'https://auth.piisiit.com');
    expect(details['audience'], [
      '[oversized claim]',
      '[redacted claim]',
      null,
      'client',
    ]);
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
      expect(details['tokenState'], 'expired');
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

  test(
    'Classifies signature rejection even when a challenge echoes the JWT',
    () {
      final jwt = token({'iss': 'PiisiitChat', 'aud': 'PiisiitClient'});
      final output = AuthDiagnostics.describe(
        authorization: 'Bearer $jwt',
        challenges: ['signature validation failed for $jwt'],
      );
      expect(jsonDecode(output)['serverReason'], 'signature_rejected');
      expect(output, isNot(contains(jwt)));
    },
  );
}
