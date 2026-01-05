import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kReleaseMode) return;
    _log('DEBUG', message, error, stackTrace);
  }

  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    if (kReleaseMode) return;
    _log('INFO', message, error, stackTrace);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message, error, stackTrace);
  }

  static void _log(
    String level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    debugPrint('[$level] $message');
    if (error != null) {
      debugPrint('[$level] $error');
    }
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
