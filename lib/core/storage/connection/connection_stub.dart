import 'package:drift/drift.dart';

/// Fallback used only when neither dart:io nor dart:js_interop is available.
QueryExecutor openConnection() =>
    throw UnsupportedError('No database connection available on this platform');
