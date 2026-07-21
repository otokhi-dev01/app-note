import '../../../../core/network/api_exception.dart';

String authErrorMessage(Object error) {
  if (error is ApiException) {
    final String message = error.message.trim();
    return message.isEmpty ? 'The request failed. Please try again.' : message;
  }

  final String message = error.toString().trim();

  if (message.isEmpty) {
    return 'The request failed. Please try again.';
  }

  return message.replaceFirst(RegExp(r'^Exception:\s*'), '');
}
