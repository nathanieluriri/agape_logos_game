import 'package:drift/drift.dart';

import '../../../core/storage/app_database.dart';
import '../domain/profile.dart';

Profile profileFromRow(CachedProfileRow row) => Profile(
      uid: row.uid,
      displayName: row.displayName,
      avatarId: row.avatarId,
      locale: row.locale,
      soundEnabled: row.soundEnabled,
      musicEnabled: row.musicEnabled,
      highestLevel: row.highestLevel,
      totalScore: row.totalScore,
      coins: row.coins,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );

CachedProfileCompanion profileToCompanion(Profile p) =>
    CachedProfileCompanion.insert(
      id: const Value(0),
      uid: p.uid,
      displayName: p.displayName,
      avatarId: p.avatarId,
      locale: p.locale,
      soundEnabled: p.soundEnabled,
      musicEnabled: p.musicEnabled,
      highestLevel: p.highestLevel,
      totalScore: p.totalScore,
      coins: Value(p.coins),
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    );
