import 'package:logging/logging.dart';

/// Shared application logger.
final Logger logger = Logger('agape');

/// Wires up logging output. Call once during bootstrap.
void configureLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((LogRecord record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.loggerName}: ${record.message}');
  });
}
