import 'package:Note/core/error/failures.dart';

/// Popup feedback is disabled throughout the app.
/// Keep the shared API so feature flows can report outcomes without overlays.
class AppSnackbar {
  AppSnackbar._();

  static void success(String title, [String message = '']) {}

  static void info(String title, [String message = '']) {}

  static void warning(String title, [String message = '']) {}

  static void error(String title, [String message = '']) {}

  static void failure(String title, AppFailure failure) {}
}
