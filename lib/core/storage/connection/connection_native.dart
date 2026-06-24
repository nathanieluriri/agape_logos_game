import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// One-time per-connection setup, applied on EVERY open in BOTH the foreground
/// and the WorkManager background isolate. WAL lets a writer and readers proceed
/// concurrently; the busy timeout makes a second concurrent writer wait-and-retry
/// instead of throwing `SQLITE_BUSY` ("database is locked"). Must be a top-level
/// function: it is sent to Drift's background isolate by `createInBackground`.
void applySqlitePragmas(Database db) {
  db.execute('PRAGMA busy_timeout = 5000;');
  db.execute('PRAGMA journal_mode = WAL;');
  db.execute('PRAGMA synchronous = NORMAL;');
}

/// Native (Android) Drift connection backed by `sqlite3_flutter_libs`.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dir.path, 'agape.sqlite'));
    return NativeDatabase.createInBackground(file, setup: applySqlitePragmas);
  });
}
