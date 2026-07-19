import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/haptics/haptics.dart';
import '../domain/match_rack.dart';

/// Why the controller rejected a completed word (issue #63): distinguishes an
/// unrecognized word from one already credited, so the UI can flash a
/// different message for each instead of one indistinct "nothing happened".
enum WordRejectReason { invalid, alreadyFound }

/// A one-shot rejection signal (issue #63). [nonce] is bumped on every
/// rejection, even a repeat of the same [reason], so a widget comparing it to
/// the previous value can tell a fresh rejection from a rebuild that merely
/// re-reads the same state, and flash its cue again for back-to-back misses.
@immutable
class WordRejection {
  const WordRejection({required this.reason, required this.nonce});
  final WordRejectReason reason;
  final int nonce;
}

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
    this.rejection,
  });

  final int rackLength;
  final List<int> rackOrder;
  final List<int> selection;
  final Set<String> pendingFound;
  final Map<String, int> revealed;
  final Set<String> appliedEventIds;

  /// The most recent word rejection (issue #63), or null before any word has
  /// been rejected this match. Never reset back to null: consumers detect a
  /// fresh rejection by comparing [WordRejection.nonce], not by nullness.
  final WordRejection? rejection;

  MatchPlayState copyWith({
    int? rackLength,
    List<int>? rackOrder,
    List<int>? selection,
    Set<String>? pendingFound,
    Map<String, int>? revealed,
    Set<String>? appliedEventIds,
    WordRejection? rejection,
  }) => MatchPlayState(
    rackLength: rackLength ?? this.rackLength,
    rackOrder: rackOrder ?? this.rackOrder,
    selection: selection ?? this.selection,
    pendingFound: pendingFound ?? this.pendingFound,
    revealed: revealed ?? this.revealed,
    appliedEventIds: appliedEventIds ?? this.appliedEventIds,
    rejection: rejection ?? this.rejection,
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
      // Invalid word: distinct error buzz so a miss is felt, not silent, plus
      // a visible shake/flash cue (issue #63) since haptics alone are
      // invisible on web and easy to miss on Android.
      Haptics.instance.mistakeImpact();
      _reject(WordRejectReason.invalid);
      return null;
    }
    if (alreadyFound.contains(word) || state.pendingFound.contains(word)) {
      // Already found: acknowledge the trace with a light tick, plus the same
      // visible cue with a distinct message (issue #63).
      Haptics.instance.selectionClick();
      _reject(WordRejectReason.alreadyFound);
      return null;
    }
    // A fresh, valid word: solid celebratory landing.
    Haptics.instance.streakImpact();
    state = state.copyWith(pendingFound: {...state.pendingFound, word});
    return word;
  }

  // Monotonic counter behind WordRejection.nonce (issue #63): incremented on
  // every rejection so two rejections in a row (even the same reason) are
  // never mistaken for the same one-shot signal by a listening widget.
  int _rejectionNonce = 0;

  void _reject(WordRejectReason reason) {
    _rejectionNonce++;
    state = state.copyWith(
      rejection: WordRejection(reason: reason, nonce: _rejectionNonce),
    );
  }

  /// Rolls back the optimistic word recorded by [endSelection] after the server
  /// REJECTED the submit (frozen / not_active / duplicate / steal race) or the
  /// submit never arrived (offline / 5xx). Removes it from `pendingFound` so the
  /// board stops showing an uncredited word AND clears the duplicate guard
  /// (which keys on `pendingFound.contains(word)`), so the same word can be
  /// re-traced and re-submitted later once the blocker clears. A no-op if the
  /// word is not currently pending (already reconciled by a rack tick).
  void rollbackSubmit(String word) {
    final w = word.toUpperCase();
    if (!state.pendingFound.contains(w)) return;
    state = state.copyWith(
      pendingFound: {...state.pendingFound}..remove(w),
    );
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
