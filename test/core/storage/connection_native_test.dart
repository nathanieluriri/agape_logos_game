import 'dart:io';

import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/core/storage/connection/connection_native.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('applySqlitePragmas enables WAL and a 5s busy timeout', () async {
    final dir = Directory.systemTemp.createTempSync('agape_pragma');
    final file = File(p.join(dir.path, 'test.sqlite'));
    final db = AppDatabase.forTesting(
      NativeDatabase(file, setup: applySqlitePragmas),
    );
    addTearDown(() async {
      await db.close();
      dir.deleteSync(recursive: true);
    });

    final journal = await db.customSelect('PRAGMA journal_mode').getSingle();
    final timeout = await db.customSelect('PRAGMA busy_timeout').getSingle();

    expect(journal.data['journal_mode'], 'wal');
    expect(timeout.data['timeout'], 5000);
  });
}
