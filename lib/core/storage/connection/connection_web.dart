import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Web Drift connection backed by WASM sqlite3.
///
/// Requires `sqlite3.wasm` and `drift_worker.js` to be present in `web/`.
QueryExecutor openConnection() {
  return DatabaseConnection.delayed(Future(() async {
    final WasmDatabaseResult result = await WasmDatabase.open(
      databaseName: 'agape',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  }));
}
