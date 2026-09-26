import 'package:flutter_test/flutter_test.dart';

import 'package:Note/features/auth/data/models/auth_model.dart';

void main() {
  group('AuthResponse access-token selection', () {
    for (final envelope in ['data', 'Data', 'payload', 'result']) {
      for (final field in ['accessToken', 'AccessToken', 'access_token']) {
        test('Reads $envelope.$field ahead of a generic token', () {
          final response = AuthResponse.fromJson({
            'success': true,
            envelope: {field: 'access-value', 'token': 'generic-value'},
          });
          expect(response.token, 'access-value');
          expect(response.isSuccess, isTrue);
        });
      }
    }

    test('Root access token outranks nested generic token', () {
      final response = AuthResponse.fromJson({
        'accessToken': 'root-access',
        'data': {'Token': 'nested-generic'},
      }, statusCode: 200);
      expect(response.token, 'root-access');
    });

    test('Nested access token outranks root generic and access tokens', () {
      final response = AuthResponse.fromJson({
        'accessToken': 'root-access',
        'token': 'root-generic',
        'data': {'access_token': 'nested-access'},
      });
      expect(response.token, 'nested-access');
    });

    test('Root explicit access token outranks a string envelope', () {
      final response = AuthResponse.fromJson({
        'AccessToken': 'root-access',
        'data': 'legacy-string',
      });
      expect(response.token, 'root-access');
    });

    test('Skips empty and non-string access-token candidates', () {
      final response = AuthResponse.fromJson({
        'access_token': 'root-access',
        'data': {
          'accessToken': '   ',
          'AccessToken': {'validation': 'invalid'},
          'access_token': 123,
          'token': 'nested-generic',
        },
      });
      expect(response.token, 'root-access');
    });

    test('Keeps raw text for the centralized normalization helper', () {
      final response = AuthResponse.fromJson({
        'data': {'accessToken': '  Bearer access-value  '},
      });
      expect(response.token, '  Bearer access-value  ');
    });

    for (final field in ['token', 'Token', 'jwt']) {
      test('Supports legacy $field after empty access fields', () {
        final response = AuthResponse.fromJson({
          'data': {'accessToken': '', field: 'legacy-access'},
        });
        expect(response.token, 'legacy-access');
      });
    }

    test('Supports legacy string data', () {
      final response = AuthResponse.fromJson({'data': 'legacy-access'});
      expect(response.token, 'legacy-access');
    });

    test('Does not use a refresh token or ID token as an access token', () {
      final response = AuthResponse.fromJson({
        'success': true,
        'refreshToken': 'root-refresh',
        'idToken': 'root-id',
        'data': {
          'refreshToken': 'nested-refresh',
          'RefreshToken': 'other-refresh',
          'refresh_token': 'snake-refresh',
          'idToken': 'nested-id',
          'id_token': 'snake-id',
        },
      });
      expect(response.token, isEmpty);
      expect(response.refreshToken, 'nested-refresh');
    });

    test('Missing, empty, and non-string token fields stay missing', () {
      for (final body in <Map<String, dynamic>>[
        {},
        {'data': null},
        {'data': '  '},
        {'token': false},
        {
          'data': {'token': []},
        },
        {
          'accessToken': 1,
          'data': {'Token': {}},
        },
      ]) {
        expect(AuthResponse.fromJson(body).token, isEmpty);
      }
    });

    test('Error envelope validation details are not credentials or a user', () {
      final response = AuthResponse.fromJson({
        'Success': false,
        'Code': 401,
        'Message': 'Invalid account or password.',
        'Data': {
          'accessToken': ['Token is required'],
          'token': {'error': 'invalid'},
          'userId': 'validation-field',
        },
      }, statusCode: 401);
      expect(response.isSuccess, isFalse);
      expect(response.token, isEmpty);
      expect(response.user.id, isNull);
      expect(response.message, 'Invalid account or password.');
    });
  });
}
