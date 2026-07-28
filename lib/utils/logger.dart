import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static final _logger = Logger(
    // Single-line output in debug; silence in release (PERF-04 fix)
    printer: kDebugMode
        ? SimplePrinter(colors: true, printTime: false)
        : SimplePrinter(colors: false, printTime: true),
    level: kDebugMode ? Level.trace : Level.warning,
  );

  /// Test-only hook: register a listener that captures every raw log
  /// event (post-filter, pre-format) emitted by the app. Production
  /// callers should not touch this.
  @visibleForTesting
  static void addTestListener(void Function(LogEvent event) cb) {
    Logger.addLogListener(cb);
  }

  /// Test-only hook: remove a listener previously registered with
  /// [addTestListener]. Production callers should not touch this.
  @visibleForTesting
  static void removeTestListener(void Function(LogEvent event) cb) {
    Logger.removeLogListener(cb);
  }

  static void debug(dynamic message) => _logger.d(message);
  static void info(dynamic message) => _logger.i(message);
  static void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.w(message, error: error, stackTrace: stackTrace);
  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
  static void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.f(message, error: error, stackTrace: stackTrace);
}
