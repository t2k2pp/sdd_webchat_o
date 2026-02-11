import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void info(String message) {
    developer.log(message, name: 'sdd_webchat_o');
  }

  static void error(String message, Object error, StackTrace stackTrace) {
    developer.log(
      message,
      name: 'sdd_webchat_o',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }

  static void debug(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'sdd_webchat_o.debug');
    }
  }
}
