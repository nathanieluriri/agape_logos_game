import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/logging/app_logger.dart';
import '../domain/puzzle.dart';

/// Source of last-resort puzzles used when the local cache is empty and the
/// network is unreachable (e.g. a fresh install with no connectivity yet).
abstract class PuzzleSeedSource {
  Future<List<Puzzle>> load();
}

/// Loads the small puzzle pack bundled with the app so gameplay never sits
/// on an empty-cache spinner before the first successful sync.
class BundledPuzzleSeedSource implements PuzzleSeedSource {
  const BundledPuzzleSeedSource({
    this.assetPath = 'assets/puzzles/starter_pack.json',
  });

  final String assetPath;

  @override
  Future<List<Puzzle>> load() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final list = (decoded['puzzles'] as List?) ?? const [];
      return list
          .map((p) => Puzzle.fromJson((p as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      // Missing/corrupt bundled asset should never crash gameplay; just play
      // with whatever cache (possibly none) is already there.
      logger.warning('bundled starter puzzle pack failed to load: $e');
      return const [];
    }
  }
}
