import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/offline/mutation.dart';
import '../../../core/offline/offline_aware_repository.dart';
import '../../../core/storage/app_database.dart';
import '../domain/level_result.dart';
import '../domain/level_result_repository.dart';

/// Mutation `kind` for level-completion writes; reconcilers key off this.
const String kLevelResultKind = 'level_result';

/// Optimistic implementation: write to the local cache instantly, then enqueue
/// the server mutation for the sync engine to replay.
class LevelResultRepositoryImpl
    with OfflineAwareRepository
    implements LevelResultRepository {
  LevelResultRepositoryImpl(this.db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  @override
  final AppDatabase db;
  final Uuid _uuid;

  @override
  Future<void> recordCompletion(LevelResult result) async {
    // 1) Apply locally NOW - this is the UI source of truth.
    await db.levelResultsDao.upsert(
      LevelResultsCompanion.insert(
        id: result.id,
        levelId: result.levelId,
        score: result.score,
        completedAt: result.completedAt,
      ),
    );
    // 2) Enqueue the optimistic mutation for later sync.
    await enqueueMutation(
      PendingMutationData(
        id: _uuid.v4(),
        endpoint: '/levels/${result.levelId}/result',
        method: 'POST',
        payloadJson: jsonEncode(result.toJson()),
        idempotencyKey: result.id,
        kind: kLevelResultKind,
        createdAt: result.completedAt,
      ),
    );
  }

  @override
  Stream<List<LevelResult>> watchAll() {
    return db.levelResultsDao.watchAll().map(
          (rows) => rows
              .map(
                (r) => LevelResult(
                  id: r.id,
                  levelId: r.levelId,
                  score: r.score,
                  completedAt: r.completedAt,
                  synced: r.synced,
                ),
              )
              .toList(),
        );
  }
}
