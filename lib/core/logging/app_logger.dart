import 'package:logging/logging.dart';

/// Shared application logger.
final Logger logger = Logger('agape');

/// Wires up logging output. Call once during bootstrap.
void configureLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((LogRecord record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.loggerName}: ${record.message}');
    // The error and stack are the whole point of a warning/severe record;
    // dropping them (as this listener used to) turns every failure into an
    // unactionable one-liner. Printed as separate lines so the message still
    // reads cleanly when there is no error attached.
    final Object? error = record.error;
    if (error != null) {
      // ignore: avoid_print
      print('  error: $error');
    }
    final StackTrace? stack = record.stackTrace;
    if (stack != null) {
      // ignore: avoid_print
      print('  stack: $stack');
    }
  });
}
