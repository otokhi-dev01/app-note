import 'package:flutter_test/flutter_test.dart';
import 'package:Note/core/network/access_token.dart';

void main() {
  const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJDaGF0In0.c2lnbmF0dXJl';

  test('Missing inputs normalize to an empty token', () {
    for (final input in <String?>[null, '', ' \t\n ', 'Bearer', 'Bearer  ']) {
      expect(AccessToken.normalize(input).value, isEmpty);
    }
  });

  test('Preserves the raw JWT bytes', () {
    final normalized = AccessToken.normalize(jwt);
    expect(normalized.value, jwt);
    expect(normalized.bearerPrefixRemoved, isFalse);
    expect(normalized.duplicateBearerPrefix, isFalse);
    expect(normalized.hadWhitespace, isFalse);
  });

  test('Trims outer whitespace and removes existing Bearer prefixes', () {
    final normalized = AccessToken.normalize(' \tBearer $jwt\n');
    expect(normalized.value, jwt);
    expect(normalized.bearerPrefixRemoved, isTrue);
    expect(normalized.duplicateBearerPrefix, isFalse);
    expect(normalized.hadWhitespace, isTrue);
  });

  test('Repairs repeated prefixes with mixed case, spaces, and tabs', () {
    final normalized = AccessToken.normalize('bEaReR\t BEARER   bearer\t$jwt');
    expect(normalized.value, jwt);
    expect(normalized.bearerPrefixRemoved, isTrue);
    expect(normalized.duplicateBearerPrefix, isTrue);
    expect('Bearer ${normalized.value}', 'Bearer $jwt');
  });

  test(
    'Only removes a whole Bearer scheme and leaves interior bytes alone',
    () {
      for (final value in [
        'BearerLike.header.signature',
        'Bearer$jwt',
        'a. b.c',
      ]) {
        expect(AccessToken.normalize(value).value, value);
      }
      expect(AccessToken.normalize('a. b.c').hadWhitespace, isTrue);
    },
  );

  test('Normalization is idempotent', () {
    final normalized = AccessToken.normalize(' Bearer Bearer $jwt ');
    final again = AccessToken.normalize(normalized.value);
    expect(again.value, jwt);
    expect(again.bearerPrefixRemoved, isFalse);
    expect(again.duplicateBearerPrefix, isFalse);
    expect(again.hadWhitespace, isFalse);
  });
}
