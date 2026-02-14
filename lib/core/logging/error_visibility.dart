import 'package:flutter/material.dart';

import 'app_logger.dart';

class ErrorVisibility {
  const ErrorVisibility._();

  static void logOnly(
    String logMessage, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    AppLogger.warning(logMessage, error, stackTrace);
  }

  static void notifyUser(
    BuildContext context, {
    required String userMessage,
    required String logMessage,
    Object? error,
    StackTrace? stackTrace,
  }) {
    AppLogger.warning(logMessage, error, stackTrace);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(userMessage)));
  }
}
