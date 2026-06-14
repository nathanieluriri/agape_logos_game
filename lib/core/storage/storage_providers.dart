import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

/// The opened database. Overridden in `bootstrap()` with the real instance.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);
