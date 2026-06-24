// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PendingMutationsTable extends PendingMutations
    with TableInfo<$PendingMutationsTable, PendingMutation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingMutationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endpointMeta = const VerificationMeta(
    'endpoint',
  );
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
    'endpoint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<int> nextAttemptAt = GeneratedColumn<int>(
    'next_attempt_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    endpoint,
    method,
    payloadJson,
    idempotencyKey,
    kind,
    createdAt,
    retryCount,
    nextAttemptAt,
    status,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_mutations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingMutation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('endpoint')) {
      context.handle(
        _endpointMeta,
        endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta),
      );
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingMutation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingMutation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      endpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $PendingMutationsTable createAlias(String alias) {
    return $PendingMutationsTable(attachedDatabase, alias);
  }
}

class PendingMutation extends DataClass implements Insertable<PendingMutation> {
  final String id;
  final String endpoint;
  final String method;
  final String payloadJson;
  final String idempotencyKey;
  final String kind;
  final int createdAt;
  final int retryCount;
  final int nextAttemptAt;
  final String status;
  final String? lastError;
  const PendingMutation({
    required this.id,
    required this.endpoint,
    required this.method,
    required this.payloadJson,
    required this.idempotencyKey,
    required this.kind,
    required this.createdAt,
    required this.retryCount,
    required this.nextAttemptAt,
    required this.status,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['endpoint'] = Variable<String>(endpoint);
    map['method'] = Variable<String>(method);
    map['payload_json'] = Variable<String>(payloadJson);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['kind'] = Variable<String>(kind);
    map['created_at'] = Variable<int>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    map['next_attempt_at'] = Variable<int>(nextAttemptAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  PendingMutationsCompanion toCompanion(bool nullToAbsent) {
    return PendingMutationsCompanion(
      id: Value(id),
      endpoint: Value(endpoint),
      method: Value(method),
      payloadJson: Value(payloadJson),
      idempotencyKey: Value(idempotencyKey),
      kind: Value(kind),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      nextAttemptAt: Value(nextAttemptAt),
      status: Value(status),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory PendingMutation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingMutation(
      id: serializer.fromJson<String>(json['id']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      method: serializer.fromJson<String>(json['method']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      kind: serializer.fromJson<String>(json['kind']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      nextAttemptAt: serializer.fromJson<int>(json['nextAttemptAt']),
      status: serializer.fromJson<String>(json['status']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'endpoint': serializer.toJson<String>(endpoint),
      'method': serializer.toJson<String>(method),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'kind': serializer.toJson<String>(kind),
      'createdAt': serializer.toJson<int>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'nextAttemptAt': serializer.toJson<int>(nextAttemptAt),
      'status': serializer.toJson<String>(status),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  PendingMutation copyWith({
    String? id,
    String? endpoint,
    String? method,
    String? payloadJson,
    String? idempotencyKey,
    String? kind,
    int? createdAt,
    int? retryCount,
    int? nextAttemptAt,
    String? status,
    Value<String?> lastError = const Value.absent(),
  }) => PendingMutation(
    id: id ?? this.id,
    endpoint: endpoint ?? this.endpoint,
    method: method ?? this.method,
    payloadJson: payloadJson ?? this.payloadJson,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    kind: kind ?? this.kind,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    status: status ?? this.status,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  PendingMutation copyWithCompanion(PendingMutationsCompanion data) {
    return PendingMutation(
      id: data.id.present ? data.id.value : this.id,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      method: data.method.present ? data.method.value : this.method,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      kind: data.kind.present ? data.kind.value : this.kind,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      status: data.status.present ? data.status.value : this.status,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingMutation(')
          ..write('id: $id, ')
          ..write('endpoint: $endpoint, ')
          ..write('method: $method, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    endpoint,
    method,
    payloadJson,
    idempotencyKey,
    kind,
    createdAt,
    retryCount,
    nextAttemptAt,
    status,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingMutation &&
          other.id == this.id &&
          other.endpoint == this.endpoint &&
          other.method == this.method &&
          other.payloadJson == this.payloadJson &&
          other.idempotencyKey == this.idempotencyKey &&
          other.kind == this.kind &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.status == this.status &&
          other.lastError == this.lastError);
}

class PendingMutationsCompanion extends UpdateCompanion<PendingMutation> {
  final Value<String> id;
  final Value<String> endpoint;
  final Value<String> method;
  final Value<String> payloadJson;
  final Value<String> idempotencyKey;
  final Value<String> kind;
  final Value<int> createdAt;
  final Value<int> retryCount;
  final Value<int> nextAttemptAt;
  final Value<String> status;
  final Value<String?> lastError;
  final Value<int> rowid;
  const PendingMutationsCompanion({
    this.id = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.method = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.kind = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingMutationsCompanion.insert({
    required String id,
    required String endpoint,
    required String method,
    required String payloadJson,
    required String idempotencyKey,
    required String kind,
    required int createdAt,
    this.retryCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       endpoint = Value(endpoint),
       method = Value(method),
       payloadJson = Value(payloadJson),
       idempotencyKey = Value(idempotencyKey),
       kind = Value(kind),
       createdAt = Value(createdAt);
  static Insertable<PendingMutation> custom({
    Expression<String>? id,
    Expression<String>? endpoint,
    Expression<String>? method,
    Expression<String>? payloadJson,
    Expression<String>? idempotencyKey,
    Expression<String>? kind,
    Expression<int>? createdAt,
    Expression<int>? retryCount,
    Expression<int>? nextAttemptAt,
    Expression<String>? status,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (endpoint != null) 'endpoint': endpoint,
      if (method != null) 'method': method,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (kind != null) 'kind': kind,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (status != null) 'status': status,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingMutationsCompanion copyWith({
    Value<String>? id,
    Value<String>? endpoint,
    Value<String>? method,
    Value<String>? payloadJson,
    Value<String>? idempotencyKey,
    Value<String>? kind,
    Value<int>? createdAt,
    Value<int>? retryCount,
    Value<int>? nextAttemptAt,
    Value<String>? status,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return PendingMutationsCompanion(
      id: id ?? this.id,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      payloadJson: payloadJson ?? this.payloadJson,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingMutationsCompanion(')
          ..write('id: $id, ')
          ..write('endpoint: $endpoint, ')
          ..write('method: $method, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LevelResultsTable extends LevelResults
    with TableInfo<$LevelResultsTable, LevelResultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LevelResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelIdMeta = const VerificationMeta(
    'levelId',
  );
  @override
  late final GeneratedColumn<int> levelId = GeneratedColumn<int>(
    'level_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    levelId,
    score,
    completedAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'level_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<LevelResultRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('level_id')) {
      context.handle(
        _levelIdMeta,
        levelId.isAcceptableOrUnknown(data['level_id']!, _levelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_levelIdMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LevelResultRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LevelResultRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      levelId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level_id'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $LevelResultsTable createAlias(String alias) {
    return $LevelResultsTable(attachedDatabase, alias);
  }
}

class LevelResultRow extends DataClass implements Insertable<LevelResultRow> {
  final String id;
  final int levelId;
  final int score;
  final int completedAt;
  final bool synced;
  const LevelResultRow({
    required this.id,
    required this.levelId,
    required this.score,
    required this.completedAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['level_id'] = Variable<int>(levelId);
    map['score'] = Variable<int>(score);
    map['completed_at'] = Variable<int>(completedAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  LevelResultsCompanion toCompanion(bool nullToAbsent) {
    return LevelResultsCompanion(
      id: Value(id),
      levelId: Value(levelId),
      score: Value(score),
      completedAt: Value(completedAt),
      synced: Value(synced),
    );
  }

  factory LevelResultRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LevelResultRow(
      id: serializer.fromJson<String>(json['id']),
      levelId: serializer.fromJson<int>(json['levelId']),
      score: serializer.fromJson<int>(json['score']),
      completedAt: serializer.fromJson<int>(json['completedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'levelId': serializer.toJson<int>(levelId),
      'score': serializer.toJson<int>(score),
      'completedAt': serializer.toJson<int>(completedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  LevelResultRow copyWith({
    String? id,
    int? levelId,
    int? score,
    int? completedAt,
    bool? synced,
  }) => LevelResultRow(
    id: id ?? this.id,
    levelId: levelId ?? this.levelId,
    score: score ?? this.score,
    completedAt: completedAt ?? this.completedAt,
    synced: synced ?? this.synced,
  );
  LevelResultRow copyWithCompanion(LevelResultsCompanion data) {
    return LevelResultRow(
      id: data.id.present ? data.id.value : this.id,
      levelId: data.levelId.present ? data.levelId.value : this.levelId,
      score: data.score.present ? data.score.value : this.score,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LevelResultRow(')
          ..write('id: $id, ')
          ..write('levelId: $levelId, ')
          ..write('score: $score, ')
          ..write('completedAt: $completedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, levelId, score, completedAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LevelResultRow &&
          other.id == this.id &&
          other.levelId == this.levelId &&
          other.score == this.score &&
          other.completedAt == this.completedAt &&
          other.synced == this.synced);
}

class LevelResultsCompanion extends UpdateCompanion<LevelResultRow> {
  final Value<String> id;
  final Value<int> levelId;
  final Value<int> score;
  final Value<int> completedAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const LevelResultsCompanion({
    this.id = const Value.absent(),
    this.levelId = const Value.absent(),
    this.score = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LevelResultsCompanion.insert({
    required String id,
    required int levelId,
    required int score,
    required int completedAt,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       levelId = Value(levelId),
       score = Value(score),
       completedAt = Value(completedAt);
  static Insertable<LevelResultRow> custom({
    Expression<String>? id,
    Expression<int>? levelId,
    Expression<int>? score,
    Expression<int>? completedAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (levelId != null) 'level_id': levelId,
      if (score != null) 'score': score,
      if (completedAt != null) 'completed_at': completedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LevelResultsCompanion copyWith({
    Value<String>? id,
    Value<int>? levelId,
    Value<int>? score,
    Value<int>? completedAt,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return LevelResultsCompanion(
      id: id ?? this.id,
      levelId: levelId ?? this.levelId,
      score: score ?? this.score,
      completedAt: completedAt ?? this.completedAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (levelId.present) {
      map['level_id'] = Variable<int>(levelId.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LevelResultsCompanion(')
          ..write('id: $id, ')
          ..write('levelId: $levelId, ')
          ..write('score: $score, ')
          ..write('completedAt: $completedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedPuzzlesTable extends CachedPuzzles
    with TableInfo<$CachedPuzzlesTable, CachedPuzzleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPuzzlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _puzzleIdMeta = const VerificationMeta(
    'puzzleId',
  );
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
    'puzzle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tierMeta = const VerificationMeta('tier');
  @override
  late final GeneratedColumn<String> tier = GeneratedColumn<String>(
    'tier',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tierRankMeta = const VerificationMeta(
    'tierRank',
  );
  @override
  late final GeneratedColumn<int> tierRank = GeneratedColumn<int>(
    'tier_rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rackSizeMeta = const VerificationMeta(
    'rackSize',
  );
  @override
  late final GeneratedColumn<int> rackSize = GeneratedColumn<int>(
    'rack_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lettersJsonMeta = const VerificationMeta(
    'lettersJson',
  );
  @override
  late final GeneratedColumn<String> lettersJson = GeneratedColumn<String>(
    'letters_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anchorMeta = const VerificationMeta('anchor');
  @override
  late final GeneratedColumn<String> anchor = GeneratedColumn<String>(
    'anchor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answersJsonMeta = const VerificationMeta(
    'answersJson',
  );
  @override
  late final GeneratedColumn<String> answersJson = GeneratedColumn<String>(
    'answers_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answerCountMeta = const VerificationMeta(
    'answerCount',
  );
  @override
  late final GeneratedColumn<int> answerCount = GeneratedColumn<int>(
    'answer_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _assignedAtMeta = const VerificationMeta(
    'assignedAt',
  );
  @override
  late final GeneratedColumn<int> assignedAt = GeneratedColumn<int>(
    'assigned_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    puzzleId,
    tier,
    tierRank,
    rackSize,
    lettersJson,
    anchor,
    answersJson,
    answerCount,
    orderIndex,
    completed,
    assignedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_puzzles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPuzzleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('puzzle_id')) {
      context.handle(
        _puzzleIdMeta,
        puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('tier')) {
      context.handle(
        _tierMeta,
        tier.isAcceptableOrUnknown(data['tier']!, _tierMeta),
      );
    } else if (isInserting) {
      context.missing(_tierMeta);
    }
    if (data.containsKey('tier_rank')) {
      context.handle(
        _tierRankMeta,
        tierRank.isAcceptableOrUnknown(data['tier_rank']!, _tierRankMeta),
      );
    } else if (isInserting) {
      context.missing(_tierRankMeta);
    }
    if (data.containsKey('rack_size')) {
      context.handle(
        _rackSizeMeta,
        rackSize.isAcceptableOrUnknown(data['rack_size']!, _rackSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_rackSizeMeta);
    }
    if (data.containsKey('letters_json')) {
      context.handle(
        _lettersJsonMeta,
        lettersJson.isAcceptableOrUnknown(
          data['letters_json']!,
          _lettersJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lettersJsonMeta);
    }
    if (data.containsKey('anchor')) {
      context.handle(
        _anchorMeta,
        anchor.isAcceptableOrUnknown(data['anchor']!, _anchorMeta),
      );
    } else if (isInserting) {
      context.missing(_anchorMeta);
    }
    if (data.containsKey('answers_json')) {
      context.handle(
        _answersJsonMeta,
        answersJson.isAcceptableOrUnknown(
          data['answers_json']!,
          _answersJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_answersJsonMeta);
    }
    if (data.containsKey('answer_count')) {
      context.handle(
        _answerCountMeta,
        answerCount.isAcceptableOrUnknown(
          data['answer_count']!,
          _answerCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_answerCountMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('assigned_at')) {
      context.handle(
        _assignedAtMeta,
        assignedAt.isAcceptableOrUnknown(data['assigned_at']!, _assignedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_assignedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {puzzleId};
  @override
  CachedPuzzleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPuzzleRow(
      puzzleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puzzle_id'],
      )!,
      tier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tier'],
      )!,
      tierRank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tier_rank'],
      )!,
      rackSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rack_size'],
      )!,
      lettersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}letters_json'],
      )!,
      anchor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchor'],
      )!,
      answersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answers_json'],
      )!,
      answerCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}answer_count'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      assignedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}assigned_at'],
      )!,
    );
  }

  @override
  $CachedPuzzlesTable createAlias(String alias) {
    return $CachedPuzzlesTable(attachedDatabase, alias);
  }
}

class CachedPuzzleRow extends DataClass implements Insertable<CachedPuzzleRow> {
  final String puzzleId;
  final String tier;
  final int tierRank;
  final int rackSize;
  final String lettersJson;
  final String anchor;
  final String answersJson;
  final int answerCount;
  final int orderIndex;
  final bool completed;
  final int assignedAt;
  const CachedPuzzleRow({
    required this.puzzleId,
    required this.tier,
    required this.tierRank,
    required this.rackSize,
    required this.lettersJson,
    required this.anchor,
    required this.answersJson,
    required this.answerCount,
    required this.orderIndex,
    required this.completed,
    required this.assignedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['tier'] = Variable<String>(tier);
    map['tier_rank'] = Variable<int>(tierRank);
    map['rack_size'] = Variable<int>(rackSize);
    map['letters_json'] = Variable<String>(lettersJson);
    map['anchor'] = Variable<String>(anchor);
    map['answers_json'] = Variable<String>(answersJson);
    map['answer_count'] = Variable<int>(answerCount);
    map['order_index'] = Variable<int>(orderIndex);
    map['completed'] = Variable<bool>(completed);
    map['assigned_at'] = Variable<int>(assignedAt);
    return map;
  }

  CachedPuzzlesCompanion toCompanion(bool nullToAbsent) {
    return CachedPuzzlesCompanion(
      puzzleId: Value(puzzleId),
      tier: Value(tier),
      tierRank: Value(tierRank),
      rackSize: Value(rackSize),
      lettersJson: Value(lettersJson),
      anchor: Value(anchor),
      answersJson: Value(answersJson),
      answerCount: Value(answerCount),
      orderIndex: Value(orderIndex),
      completed: Value(completed),
      assignedAt: Value(assignedAt),
    );
  }

  factory CachedPuzzleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPuzzleRow(
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      tier: serializer.fromJson<String>(json['tier']),
      tierRank: serializer.fromJson<int>(json['tierRank']),
      rackSize: serializer.fromJson<int>(json['rackSize']),
      lettersJson: serializer.fromJson<String>(json['lettersJson']),
      anchor: serializer.fromJson<String>(json['anchor']),
      answersJson: serializer.fromJson<String>(json['answersJson']),
      answerCount: serializer.fromJson<int>(json['answerCount']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      completed: serializer.fromJson<bool>(json['completed']),
      assignedAt: serializer.fromJson<int>(json['assignedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'puzzleId': serializer.toJson<String>(puzzleId),
      'tier': serializer.toJson<String>(tier),
      'tierRank': serializer.toJson<int>(tierRank),
      'rackSize': serializer.toJson<int>(rackSize),
      'lettersJson': serializer.toJson<String>(lettersJson),
      'anchor': serializer.toJson<String>(anchor),
      'answersJson': serializer.toJson<String>(answersJson),
      'answerCount': serializer.toJson<int>(answerCount),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'completed': serializer.toJson<bool>(completed),
      'assignedAt': serializer.toJson<int>(assignedAt),
    };
  }

  CachedPuzzleRow copyWith({
    String? puzzleId,
    String? tier,
    int? tierRank,
    int? rackSize,
    String? lettersJson,
    String? anchor,
    String? answersJson,
    int? answerCount,
    int? orderIndex,
    bool? completed,
    int? assignedAt,
  }) => CachedPuzzleRow(
    puzzleId: puzzleId ?? this.puzzleId,
    tier: tier ?? this.tier,
    tierRank: tierRank ?? this.tierRank,
    rackSize: rackSize ?? this.rackSize,
    lettersJson: lettersJson ?? this.lettersJson,
    anchor: anchor ?? this.anchor,
    answersJson: answersJson ?? this.answersJson,
    answerCount: answerCount ?? this.answerCount,
    orderIndex: orderIndex ?? this.orderIndex,
    completed: completed ?? this.completed,
    assignedAt: assignedAt ?? this.assignedAt,
  );
  CachedPuzzleRow copyWithCompanion(CachedPuzzlesCompanion data) {
    return CachedPuzzleRow(
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      tier: data.tier.present ? data.tier.value : this.tier,
      tierRank: data.tierRank.present ? data.tierRank.value : this.tierRank,
      rackSize: data.rackSize.present ? data.rackSize.value : this.rackSize,
      lettersJson: data.lettersJson.present
          ? data.lettersJson.value
          : this.lettersJson,
      anchor: data.anchor.present ? data.anchor.value : this.anchor,
      answersJson: data.answersJson.present
          ? data.answersJson.value
          : this.answersJson,
      answerCount: data.answerCount.present
          ? data.answerCount.value
          : this.answerCount,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      completed: data.completed.present ? data.completed.value : this.completed,
      assignedAt: data.assignedAt.present
          ? data.assignedAt.value
          : this.assignedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPuzzleRow(')
          ..write('puzzleId: $puzzleId, ')
          ..write('tier: $tier, ')
          ..write('tierRank: $tierRank, ')
          ..write('rackSize: $rackSize, ')
          ..write('lettersJson: $lettersJson, ')
          ..write('anchor: $anchor, ')
          ..write('answersJson: $answersJson, ')
          ..write('answerCount: $answerCount, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('completed: $completed, ')
          ..write('assignedAt: $assignedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    puzzleId,
    tier,
    tierRank,
    rackSize,
    lettersJson,
    anchor,
    answersJson,
    answerCount,
    orderIndex,
    completed,
    assignedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPuzzleRow &&
          other.puzzleId == this.puzzleId &&
          other.tier == this.tier &&
          other.tierRank == this.tierRank &&
          other.rackSize == this.rackSize &&
          other.lettersJson == this.lettersJson &&
          other.anchor == this.anchor &&
          other.answersJson == this.answersJson &&
          other.answerCount == this.answerCount &&
          other.orderIndex == this.orderIndex &&
          other.completed == this.completed &&
          other.assignedAt == this.assignedAt);
}

class CachedPuzzlesCompanion extends UpdateCompanion<CachedPuzzleRow> {
  final Value<String> puzzleId;
  final Value<String> tier;
  final Value<int> tierRank;
  final Value<int> rackSize;
  final Value<String> lettersJson;
  final Value<String> anchor;
  final Value<String> answersJson;
  final Value<int> answerCount;
  final Value<int> orderIndex;
  final Value<bool> completed;
  final Value<int> assignedAt;
  final Value<int> rowid;
  const CachedPuzzlesCompanion({
    this.puzzleId = const Value.absent(),
    this.tier = const Value.absent(),
    this.tierRank = const Value.absent(),
    this.rackSize = const Value.absent(),
    this.lettersJson = const Value.absent(),
    this.anchor = const Value.absent(),
    this.answersJson = const Value.absent(),
    this.answerCount = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.completed = const Value.absent(),
    this.assignedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPuzzlesCompanion.insert({
    required String puzzleId,
    required String tier,
    required int tierRank,
    required int rackSize,
    required String lettersJson,
    required String anchor,
    required String answersJson,
    required int answerCount,
    required int orderIndex,
    this.completed = const Value.absent(),
    required int assignedAt,
    this.rowid = const Value.absent(),
  }) : puzzleId = Value(puzzleId),
       tier = Value(tier),
       tierRank = Value(tierRank),
       rackSize = Value(rackSize),
       lettersJson = Value(lettersJson),
       anchor = Value(anchor),
       answersJson = Value(answersJson),
       answerCount = Value(answerCount),
       orderIndex = Value(orderIndex),
       assignedAt = Value(assignedAt);
  static Insertable<CachedPuzzleRow> custom({
    Expression<String>? puzzleId,
    Expression<String>? tier,
    Expression<int>? tierRank,
    Expression<int>? rackSize,
    Expression<String>? lettersJson,
    Expression<String>? anchor,
    Expression<String>? answersJson,
    Expression<int>? answerCount,
    Expression<int>? orderIndex,
    Expression<bool>? completed,
    Expression<int>? assignedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (tier != null) 'tier': tier,
      if (tierRank != null) 'tier_rank': tierRank,
      if (rackSize != null) 'rack_size': rackSize,
      if (lettersJson != null) 'letters_json': lettersJson,
      if (anchor != null) 'anchor': anchor,
      if (answersJson != null) 'answers_json': answersJson,
      if (answerCount != null) 'answer_count': answerCount,
      if (orderIndex != null) 'order_index': orderIndex,
      if (completed != null) 'completed': completed,
      if (assignedAt != null) 'assigned_at': assignedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPuzzlesCompanion copyWith({
    Value<String>? puzzleId,
    Value<String>? tier,
    Value<int>? tierRank,
    Value<int>? rackSize,
    Value<String>? lettersJson,
    Value<String>? anchor,
    Value<String>? answersJson,
    Value<int>? answerCount,
    Value<int>? orderIndex,
    Value<bool>? completed,
    Value<int>? assignedAt,
    Value<int>? rowid,
  }) {
    return CachedPuzzlesCompanion(
      puzzleId: puzzleId ?? this.puzzleId,
      tier: tier ?? this.tier,
      tierRank: tierRank ?? this.tierRank,
      rackSize: rackSize ?? this.rackSize,
      lettersJson: lettersJson ?? this.lettersJson,
      anchor: anchor ?? this.anchor,
      answersJson: answersJson ?? this.answersJson,
      answerCount: answerCount ?? this.answerCount,
      orderIndex: orderIndex ?? this.orderIndex,
      completed: completed ?? this.completed,
      assignedAt: assignedAt ?? this.assignedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (tier.present) {
      map['tier'] = Variable<String>(tier.value);
    }
    if (tierRank.present) {
      map['tier_rank'] = Variable<int>(tierRank.value);
    }
    if (rackSize.present) {
      map['rack_size'] = Variable<int>(rackSize.value);
    }
    if (lettersJson.present) {
      map['letters_json'] = Variable<String>(lettersJson.value);
    }
    if (anchor.present) {
      map['anchor'] = Variable<String>(anchor.value);
    }
    if (answersJson.present) {
      map['answers_json'] = Variable<String>(answersJson.value);
    }
    if (answerCount.present) {
      map['answer_count'] = Variable<int>(answerCount.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (assignedAt.present) {
      map['assigned_at'] = Variable<int>(assignedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPuzzlesCompanion(')
          ..write('puzzleId: $puzzleId, ')
          ..write('tier: $tier, ')
          ..write('tierRank: $tierRank, ')
          ..write('rackSize: $rackSize, ')
          ..write('lettersJson: $lettersJson, ')
          ..write('anchor: $anchor, ')
          ..write('answersJson: $answersJson, ')
          ..write('answerCount: $answerCount, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('completed: $completed, ')
          ..write('assignedAt: $assignedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PendingMutationsTable pendingMutations = $PendingMutationsTable(
    this,
  );
  late final $LevelResultsTable levelResults = $LevelResultsTable(this);
  late final $CachedPuzzlesTable cachedPuzzles = $CachedPuzzlesTable(this);
  late final PendingMutationsDao pendingMutationsDao = PendingMutationsDao(
    this as AppDatabase,
  );
  late final LevelResultsDao levelResultsDao = LevelResultsDao(
    this as AppDatabase,
  );
  late final CachedPuzzlesDao cachedPuzzlesDao = CachedPuzzlesDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    pendingMutations,
    levelResults,
    cachedPuzzles,
  ];
}

typedef $$PendingMutationsTableCreateCompanionBuilder =
    PendingMutationsCompanion Function({
      required String id,
      required String endpoint,
      required String method,
      required String payloadJson,
      required String idempotencyKey,
      required String kind,
      required int createdAt,
      Value<int> retryCount,
      Value<int> nextAttemptAt,
      Value<String> status,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$PendingMutationsTableUpdateCompanionBuilder =
    PendingMutationsCompanion Function({
      Value<String> id,
      Value<String> endpoint,
      Value<String> method,
      Value<String> payloadJson,
      Value<String> idempotencyKey,
      Value<String> kind,
      Value<int> createdAt,
      Value<int> retryCount,
      Value<int> nextAttemptAt,
      Value<String> status,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$PendingMutationsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingMutationsTable> {
  $$PendingMutationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingMutationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingMutationsTable> {
  $$PendingMutationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingMutationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingMutationsTable> {
  $$PendingMutationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$PendingMutationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingMutationsTable,
          PendingMutation,
          $$PendingMutationsTableFilterComposer,
          $$PendingMutationsTableOrderingComposer,
          $$PendingMutationsTableAnnotationComposer,
          $$PendingMutationsTableCreateCompanionBuilder,
          $$PendingMutationsTableUpdateCompanionBuilder,
          (
            PendingMutation,
            BaseReferences<
              _$AppDatabase,
              $PendingMutationsTable,
              PendingMutation
            >,
          ),
          PendingMutation,
          PrefetchHooks Function()
        > {
  $$PendingMutationsTableTableManager(
    _$AppDatabase db,
    $PendingMutationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingMutationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingMutationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingMutationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> endpoint = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<int> nextAttemptAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingMutationsCompanion(
                id: id,
                endpoint: endpoint,
                method: method,
                payloadJson: payloadJson,
                idempotencyKey: idempotencyKey,
                kind: kind,
                createdAt: createdAt,
                retryCount: retryCount,
                nextAttemptAt: nextAttemptAt,
                status: status,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String endpoint,
                required String method,
                required String payloadJson,
                required String idempotencyKey,
                required String kind,
                required int createdAt,
                Value<int> retryCount = const Value.absent(),
                Value<int> nextAttemptAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingMutationsCompanion.insert(
                id: id,
                endpoint: endpoint,
                method: method,
                payloadJson: payloadJson,
                idempotencyKey: idempotencyKey,
                kind: kind,
                createdAt: createdAt,
                retryCount: retryCount,
                nextAttemptAt: nextAttemptAt,
                status: status,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingMutationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingMutationsTable,
      PendingMutation,
      $$PendingMutationsTableFilterComposer,
      $$PendingMutationsTableOrderingComposer,
      $$PendingMutationsTableAnnotationComposer,
      $$PendingMutationsTableCreateCompanionBuilder,
      $$PendingMutationsTableUpdateCompanionBuilder,
      (
        PendingMutation,
        BaseReferences<_$AppDatabase, $PendingMutationsTable, PendingMutation>,
      ),
      PendingMutation,
      PrefetchHooks Function()
    >;
typedef $$LevelResultsTableCreateCompanionBuilder =
    LevelResultsCompanion Function({
      required String id,
      required int levelId,
      required int score,
      required int completedAt,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$LevelResultsTableUpdateCompanionBuilder =
    LevelResultsCompanion Function({
      Value<String> id,
      Value<int> levelId,
      Value<int> score,
      Value<int> completedAt,
      Value<bool> synced,
      Value<int> rowid,
    });

class $$LevelResultsTableFilterComposer
    extends Composer<_$AppDatabase, $LevelResultsTable> {
  $$LevelResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get levelId => $composableBuilder(
    column: $table.levelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LevelResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $LevelResultsTable> {
  $$LevelResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get levelId => $composableBuilder(
    column: $table.levelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LevelResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LevelResultsTable> {
  $$LevelResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get levelId =>
      $composableBuilder(column: $table.levelId, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$LevelResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LevelResultsTable,
          LevelResultRow,
          $$LevelResultsTableFilterComposer,
          $$LevelResultsTableOrderingComposer,
          $$LevelResultsTableAnnotationComposer,
          $$LevelResultsTableCreateCompanionBuilder,
          $$LevelResultsTableUpdateCompanionBuilder,
          (
            LevelResultRow,
            BaseReferences<_$AppDatabase, $LevelResultsTable, LevelResultRow>,
          ),
          LevelResultRow,
          PrefetchHooks Function()
        > {
  $$LevelResultsTableTableManager(_$AppDatabase db, $LevelResultsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LevelResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LevelResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LevelResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> levelId = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int> completedAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LevelResultsCompanion(
                id: id,
                levelId: levelId,
                score: score,
                completedAt: completedAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int levelId,
                required int score,
                required int completedAt,
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LevelResultsCompanion.insert(
                id: id,
                levelId: levelId,
                score: score,
                completedAt: completedAt,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LevelResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LevelResultsTable,
      LevelResultRow,
      $$LevelResultsTableFilterComposer,
      $$LevelResultsTableOrderingComposer,
      $$LevelResultsTableAnnotationComposer,
      $$LevelResultsTableCreateCompanionBuilder,
      $$LevelResultsTableUpdateCompanionBuilder,
      (
        LevelResultRow,
        BaseReferences<_$AppDatabase, $LevelResultsTable, LevelResultRow>,
      ),
      LevelResultRow,
      PrefetchHooks Function()
    >;
typedef $$CachedPuzzlesTableCreateCompanionBuilder =
    CachedPuzzlesCompanion Function({
      required String puzzleId,
      required String tier,
      required int tierRank,
      required int rackSize,
      required String lettersJson,
      required String anchor,
      required String answersJson,
      required int answerCount,
      required int orderIndex,
      Value<bool> completed,
      required int assignedAt,
      Value<int> rowid,
    });
typedef $$CachedPuzzlesTableUpdateCompanionBuilder =
    CachedPuzzlesCompanion Function({
      Value<String> puzzleId,
      Value<String> tier,
      Value<int> tierRank,
      Value<int> rackSize,
      Value<String> lettersJson,
      Value<String> anchor,
      Value<String> answersJson,
      Value<int> answerCount,
      Value<int> orderIndex,
      Value<bool> completed,
      Value<int> assignedAt,
      Value<int> rowid,
    });

class $$CachedPuzzlesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedPuzzlesTable> {
  $$CachedPuzzlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tierRank => $composableBuilder(
    column: $table.tierRank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rackSize => $composableBuilder(
    column: $table.rackSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lettersJson => $composableBuilder(
    column: $table.lettersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anchor => $composableBuilder(
    column: $table.anchor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answersJson => $composableBuilder(
    column: $table.answersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get answerCount => $composableBuilder(
    column: $table.answerCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get assignedAt => $composableBuilder(
    column: $table.assignedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPuzzlesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedPuzzlesTable> {
  $$CachedPuzzlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tierRank => $composableBuilder(
    column: $table.tierRank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rackSize => $composableBuilder(
    column: $table.rackSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lettersJson => $composableBuilder(
    column: $table.lettersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchor => $composableBuilder(
    column: $table.anchor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answersJson => $composableBuilder(
    column: $table.answersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get answerCount => $composableBuilder(
    column: $table.answerCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get assignedAt => $composableBuilder(
    column: $table.assignedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPuzzlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedPuzzlesTable> {
  $$CachedPuzzlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get puzzleId =>
      $composableBuilder(column: $table.puzzleId, builder: (column) => column);

  GeneratedColumn<String> get tier =>
      $composableBuilder(column: $table.tier, builder: (column) => column);

  GeneratedColumn<int> get tierRank =>
      $composableBuilder(column: $table.tierRank, builder: (column) => column);

  GeneratedColumn<int> get rackSize =>
      $composableBuilder(column: $table.rackSize, builder: (column) => column);

  GeneratedColumn<String> get lettersJson => $composableBuilder(
    column: $table.lettersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get anchor =>
      $composableBuilder(column: $table.anchor, builder: (column) => column);

  GeneratedColumn<String> get answersJson => $composableBuilder(
    column: $table.answersJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get answerCount => $composableBuilder(
    column: $table.answerCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get assignedAt => $composableBuilder(
    column: $table.assignedAt,
    builder: (column) => column,
  );
}

class $$CachedPuzzlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedPuzzlesTable,
          CachedPuzzleRow,
          $$CachedPuzzlesTableFilterComposer,
          $$CachedPuzzlesTableOrderingComposer,
          $$CachedPuzzlesTableAnnotationComposer,
          $$CachedPuzzlesTableCreateCompanionBuilder,
          $$CachedPuzzlesTableUpdateCompanionBuilder,
          (
            CachedPuzzleRow,
            BaseReferences<_$AppDatabase, $CachedPuzzlesTable, CachedPuzzleRow>,
          ),
          CachedPuzzleRow,
          PrefetchHooks Function()
        > {
  $$CachedPuzzlesTableTableManager(_$AppDatabase db, $CachedPuzzlesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPuzzlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPuzzlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPuzzlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> puzzleId = const Value.absent(),
                Value<String> tier = const Value.absent(),
                Value<int> tierRank = const Value.absent(),
                Value<int> rackSize = const Value.absent(),
                Value<String> lettersJson = const Value.absent(),
                Value<String> anchor = const Value.absent(),
                Value<String> answersJson = const Value.absent(),
                Value<int> answerCount = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> assignedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPuzzlesCompanion(
                puzzleId: puzzleId,
                tier: tier,
                tierRank: tierRank,
                rackSize: rackSize,
                lettersJson: lettersJson,
                anchor: anchor,
                answersJson: answersJson,
                answerCount: answerCount,
                orderIndex: orderIndex,
                completed: completed,
                assignedAt: assignedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String puzzleId,
                required String tier,
                required int tierRank,
                required int rackSize,
                required String lettersJson,
                required String anchor,
                required String answersJson,
                required int answerCount,
                required int orderIndex,
                Value<bool> completed = const Value.absent(),
                required int assignedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedPuzzlesCompanion.insert(
                puzzleId: puzzleId,
                tier: tier,
                tierRank: tierRank,
                rackSize: rackSize,
                lettersJson: lettersJson,
                anchor: anchor,
                answersJson: answersJson,
                answerCount: answerCount,
                orderIndex: orderIndex,
                completed: completed,
                assignedAt: assignedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPuzzlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedPuzzlesTable,
      CachedPuzzleRow,
      $$CachedPuzzlesTableFilterComposer,
      $$CachedPuzzlesTableOrderingComposer,
      $$CachedPuzzlesTableAnnotationComposer,
      $$CachedPuzzlesTableCreateCompanionBuilder,
      $$CachedPuzzlesTableUpdateCompanionBuilder,
      (
        CachedPuzzleRow,
        BaseReferences<_$AppDatabase, $CachedPuzzlesTable, CachedPuzzleRow>,
      ),
      CachedPuzzleRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PendingMutationsTableTableManager get pendingMutations =>
      $$PendingMutationsTableTableManager(_db, _db.pendingMutations);
  $$LevelResultsTableTableManager get levelResults =>
      $$LevelResultsTableTableManager(_db, _db.levelResults);
  $$CachedPuzzlesTableTableManager get cachedPuzzles =>
      $$CachedPuzzlesTableTableManager(_db, _db.cachedPuzzles);
}
