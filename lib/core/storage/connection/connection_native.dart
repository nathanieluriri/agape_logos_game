import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Native (Android) Drift connection backed by `sqlite3_flutter_libs`.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dir.path, 'agape.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
