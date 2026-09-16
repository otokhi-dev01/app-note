import 'package:flutter_test/flutter_test.dart';
import 'package:Note/core/network/api_error_parser.dart';

void main() {
  test('Real validation messages pass through unchanged', () {
    expect(
      ApiErrorParser.messageFrom({'message': 'Invalid account or password.'}),
      'Invalid account or password.',
    );
    expect(
      ApiErrorParser.messageFrom({
        'errors': {
          'password': ['Password must be at least 6 characters.'],
        },
      }),
      'Password must be at least 6 characters.',
    );
  });

  test('A raw EF Core exception is suppressed in favor of the fallback', () {
    const efCoreError =
        "The relationship from 'UserSession' to 'UserDevice' with foreign "
        "key properties {'DeviceId' : Guid} cannot target the primary key "
        "{'UserId' : Guid, 'Id' : Guid} because it is not compatible. "
        "Configure a principal key or a set of foreign key properties with "
        "compatible types for this relationship.";

    expect(
      ApiErrorParser.messageFrom({
        'message': efCoreError,
      }, fallback: 'Something went wrong. Please try again.'),
      'Something went wrong. Please try again.',
    );
    expect(
      ApiErrorParser.messageFrom({'message': efCoreError}),
      isNot(contains('UserSession')),
    );
  });

  test('Other internal-looking errors are suppressed too', () {
    for (final leak in [
      // ignore: no_adjacent_strings_in_list
      'System.NullReferenceException: Object reference not set to an '
          'instance of an object. at System.Data.SqlClient.SqlCommand.'
          'ExecuteReader()',
      // ignore: no_adjacent_strings_in_list
      'Microsoft.EntityFrameworkCore.DbUpdateException: An error occurred '
          'while saving the entity changes. See the inner exception for '
          'details.',
    ]) {
      expect(
        ApiErrorParser.messageFrom({'message': leak}, fallback: 'Generic'),
        'Generic',
      );
    }
  });

  test('Missing message falls back to the generic text', () {
    expect(
      ApiErrorParser.messageFrom(<String, dynamic>{}),
      'Something went wrong.',
    );
    expect(ApiErrorParser.messageFrom('not a map', fallback: 'X'), 'X');
  });
}
