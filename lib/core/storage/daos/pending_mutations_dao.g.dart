// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_mutations_dao.dart';

// ignore_for_file: type=lint
mixin _$PendingMutationsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PendingMutationsTable get pendingMutations =>
      attachedDatabase.pendingMutations;
  PendingMutationsDaoManager get managers => PendingMutationsDaoManager(this);
}

class PendingMutationsDaoManager {
  final _$PendingMutationsDaoMixin _db;
  PendingMutationsDaoManager(this._db);
  $$PendingMutationsTableTableManager get pendingMutations =>
      $$PendingMutationsTableTableManager(
        _db.attachedDatabase,
        _db.pendingMutations,
      );
}
