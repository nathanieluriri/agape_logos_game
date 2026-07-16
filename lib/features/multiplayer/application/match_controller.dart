import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/haptics/haptics.dart';
import '../domain/match_rack.dart';

/// Local, client-only play state for a match. The rack letters, decrypted
/// answers, and confirmed found set live on the rack model (server-owned); this
/// holds only what the client controls between server ticks: the wheel order,
/// the in-progress selection, an optimistic found set (superseded by the
/// server's `foundWords`), and the set of one-shot event ids already applied.
@immutable
class MatchPlayState {
  const MatchPlayState({
    this.rackLength = 0,
    this.rackOrder = const [],
    this.selection = const [],
    this.pendingFound = const {},
    this.revealed = const {},
    this.appliedEventIds = const {},
  });

  final int rackLength;
  final List<int> rackOrder;
  final List<int> selection;
  final Set<String> pendingFound;
  final Map<String, int> revealed;
  final Set<String> appliedEventIds;

  MatchPlayState copyWith({
    int? rackLength,
    List<int>? rackOrder,
    List<int>? selection,
    Set<String>? pendingFound,
    Map<String, int>? revealed,
    Set<String>? appliedEventIds,
  }) => MatchPlayState(
    rackLength: rackLength ?? this.rackLength,
    rackOrder: rackOrder ?? this.rackOrder,
    selection: selection ?? this.selection,
    pendingFound: pendingFound ?? this.pendingFound,
    revealed: revealed ?? this.revealed,
    appliedEventIds: appliedEventIds ?? this.appliedEventIds,
  );
}

class MatchPlayController extends Notifier<MatchPlayState> {
  @override
  MatchPlayState build() => const MatchPlayState();

  /// Clears state for a fresh match (call when the match page mounts).
  void reset() => state = const MatchPlayState();

  /// Aligns the wheel order to the rack size (identity on first sight) and drops
  /// any optimistic word the server has now confirmed in `foundWords`.
  void syncRack(MatchRack rack) {
    final len = rack.letters.length;
    var next = state;
    if (state.rackLength != len || state.rackOrder.length != len) {
      next = next.copyWith(
        rackLength: len,
        rackOrder: List<int>.generate(len, (i) => i),
        selection: const [],
      );
    }
    if (next.pendingFound.isNotEmpty && rack.foundWords.isNotEmpty) {
      final confirmed = rack.foundWords.map((w) => w.toUpperCase()).toSet();
      final stillPending = next.pendingFound.difference(confirmed);
      if (stillPending.length != next.pendingFound.length) {
        next = next.copyWith(pendingFound: stillPending);
      }
    }
    if (!identical(next, state)) state = next;
  }

  /// Wheel letters in display order for [rack] under the current shuffle order.
  List<String> wheelLetters(MatchRack rack) => [
    for (final i in state.rackOrder)
      if (i >= 0 && i < rack.letters.length) rack.letters[i],
  ];

  void touchLetter(int slot, {Set<int> frozen = const <int>{}}) {
    if (slot < 0 || slot >= state.rackLength) return;
    if (frozen.contains(slot)) return; // a frozen node ignores touches
    if (state.selection.contains(slot)) return;
    state = state.copyWith(selection: [...state.selection, slot]);
  }

  /// Ends the drag. Returns the newly formed answer to SUBMIT to the server
  /// (uppercased), or null when the word is invalid, a duplicate, or the rack is
  /// not decrypted yet. Optimistically records the word so the board fills at
  /// once; the server's `foundWords` + score arrive via the listeners.
  String? endSelection(MatchRack rack, Set<String> alreadyFound) {
    if (state.selection.isEmpty) return null;
    final letters = wheelLetters(rack);
    final word = [
      for (final s in state.selection)
        if (s >= 0 && s < letters.length) letters[s],
    ].join().toUpperCase();
    state = state.copyWith(selection: const []);
    if (!rack.decrypted || word.isEmpty) return null;
    final isAnswer = rack.answers.any((a) => a.word.toUpperCase() == word);
    if (!isAnswer) {
      // Invalid word: distinct error buzz so a miss is felt, not silent.
      Haptics.instance.mistakeImpact();
      return null;
    }
    if (alreadyFound.contains(word) || state.pendingFound.contains(word)) {
      // Already found: acknowledge the trace with a light tick.
      Haptics.instance.selectionClick();
      return null;
    }
    // A fresh, valid word: solid celebratory landing.
    Haptics.instance.streakImpact();
    state = state.copyWith(pendingFound: {...state.pendingFound, word});
    return word;
  }

  /// Client-only hint: reveal one more letter of the first unfound target that
  /// is not already fully revealed. Local visual aid only (mirrors the
  /// single-player reveal machinery); no server call, no cost, no cap.
  void hint(MatchRack rack, Set<String> found) {
    for (final answer in rack.targets) {
      final word = answer.word.toUpperCase();
      if (found.contains(word)) continue;
      final shown = state.revealed[word] ?? 0;
      if (shown >= word.length) continue;
      state = state.copyWith(
        revealed: {...state.revealed, word: shown + 1},
      );
      return;
    }
  }

  void shuffle() {
    state = state.copyWith(
      rackOrder: [...state.rackOrder]..shuffle(),
      selection: const [],
    );
  }

  /// Incoming `scramble` effect: reshuffle the wheel ONCE per event id (Firestore
  /// re-delivers snapshots, so dedupe by id).
  void applyScramble(String eventId) {
    if (state.appliedEventIds.contains(eventId)) return;
    state = state.copyWith(
      rackOrder: [...state.rackOrder]..shuffle(),
      selection: const [],
      appliedEventIds: {...state.appliedEventIds, eventId},
    );
  }

  /// Incoming `word_steal` effect: drop the stolen word from the optimistic set
  /// so the local board stops showing it. The authoritative removal from
  /// `foundWords` + the score change arrive from the server via the listeners.
  void applyWordSteal(String eventId, String word) {
    if (state.appliedEventIds.contains(eventId)) return;
    state = state.copyWith(
      pendingFound: {...state.pendingFound}..remove(word.toUpperCase()),
      appliedEventIds: {...state.appliedEventIds, eventId},
    );
  }
}

final matchPlayControllerProvider =
    NotifierProvider<MatchPlayController, MatchPlayState>(
      MatchPlayController.new,
    );
