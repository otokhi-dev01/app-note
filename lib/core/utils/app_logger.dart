import 'dart:developer' as dev;

class AppLogger {
  static void log(String message, {String name = 'APP'}) {
    dev.log(message, name: name);
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    dev.log(message, name: 'ERROR', error: error, stackTrace: stackTrace);
  }
}
