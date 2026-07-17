import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/multiplayer/application/match_providers.dart';
import 'package:agape_logos_game/features/multiplayer/application/server_clock.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_player.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MatchPlayer _player(String uid) => MatchPlayer(
  uid: uid,
  displayName: uid,
  avatarId: 'a',
  isGuest: false,
  ready: true,
  connected: true,
  score: 0,
  wordsFound: 0,
);

Match _matchWith(Map<String, List<MatchActiveEffect>> activeEffects) => Match(
  matchId: 'm1',
  code: 'ABCD',
  status: MatchStatus.active,
  participants: const ['me', 'opp'],
  playerOrder: const ['me', 'opp'],
  createdBy: 'me',
  createdAt: 0,
  startedAt: 0,
  endsAt: 60000,
  settings: MatchSettings.defaults(),
  players: {'me': _player('me'), 'opp': _player('opp')},
  activeEffects: activeEffects,
);

void main() {
  test('parses fog, freeze-by-letter, double points and armed shield from the match doc', () async {
    final future2 = DateTime.now().millisecondsSinceEpoch + 60000;
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1').overrideWith(
          (ref) => Stream.value(
            _matchWith({
              'me': [
                MatchActiveEffect(
                  kind: MatchEffectKind.fogBank,
                  byUid: 'opp',
                  startedAt: 0,
                  expiresAt: future2,
                  payload: const {},
                ),
                MatchActiveEffect(
                  kind: MatchEffectKind.letterFreeze,
                  byUid: 'opp',
                  startedAt: 0,
                  expiresAt: future2,
                  payload: const {'letter': 'A'},
                ),
                const MatchActiveEffect(
                  kind: MatchEffectKind.doublePoints,
                  byUid: 'me',
                  startedAt: 0,
                  expiresAt: 0,
                  payload: {},
                ),
                const MatchActiveEffect(
                  kind: MatchEffectKind.shield,
                  byUid: 'me',
                  startedAt: 0,
                  expiresAt: 0,
                  payload: {},
                ),
              ],
            }),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(matchStreamProvider('m1'), (_, __) {});
    await container.pump();

    final fx = container.read(activeEffectsProvider('m1'));
    expect(fx.fog, isTrue);
    expect(fx.frozenLetter, 'A');
    expect(fx.frozenLetterCp, 'A'.codeUnitAt(0));
    // double_points has expiresAt 0 but isn't armed-until-consumed like
    // shield: MatchEffectKind.doublePoints just has no timed expiry in this
    // fixture, so it counts as live.
    expect(fx.doublePoints, isTrue);
    expect(fx.shieldArmed, isTrue);
  });

  test('expiry honors server-clock offset when the device clock is ahead', () async {
    final clock = ServerClock();
    // Device thinks it is 5 minutes later than the server.
    final serverNowMs = DateTime.now().millisecondsSinceEpoch - 300000;
    clock.sync(serverNowMs);
    // An effect that expires 60s after the server's (older) now is already
    // lapsed by the device clock, but still live by the server-corrected one.
    final expiresAt = serverNowMs + 60000;

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        serverClockProvider.overrideWithValue(clock),
        matchStreamProvider('m1').overrideWith(
          (ref) => Stream.value(
            _matchWith({
              'me': [
                MatchActiveEffect(
                  kind: MatchEffectKind.fogBank,
                  byUid: 'opp',
                  startedAt: 0,
                  expiresAt: expiresAt,
                  payload: const {},
                ),
              ],
            }),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(matchStreamProvider('m1'), (_, __) {});
    await container.pump();

    final fx = container.read(activeEffectsProvider('m1'));
    expect(fx.fog, isTrue);
  });

  test('drops an effect whose expiry has lapsed by server time', () async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1').overrideWith(
          (ref) => Stream.value(
            _matchWith({
              'me': [
                MatchActiveEffect(
                  kind: MatchEffectKind.fogBank,
                  byUid: 'opp',
                  startedAt: 0,
                  expiresAt: DateTime.now().millisecondsSinceEpoch - 1000,
                  payload: const {},
                ),
              ],
            }),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(matchStreamProvider('m1'), (_, __) {});
    await container.pump();

    final fx = container.read(activeEffectsProvider('m1'));
    expect(fx.fog, isFalse);
  });

  test('warded reads combo_lock STATE from the match doc (reconnect-safe)', () async {
    // A reconnecting client has NO events replayed; the ward must come from
    // the persisted activeEffects alone.
    final until = DateTime.now().millisecondsSinceEpoch + 45000;
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1').overrideWith(
          (ref) => Stream.value(
            _matchWith({
              'me': [
                MatchActiveEffect(
                  kind: MatchEffectKind.comboLock,
                  byUid: 'me',
                  startedAt: 0,
                  expiresAt: until,
                  payload: const {},
                ),
              ],
            }),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(matchStreamProvider('m1'), (_, __) {});
    await container.pump();

    final fx = container.read(activeEffectsProvider('m1'));
    expect(fx.warded, isTrue);
    expect(fx.wardUntil, DateTime.fromMillisecondsSinceEpoch(until));
  });

  test('ward stays active under a device-ahead clock once ServerClock synced', () async {
    final clock = ServerClock();
    // Device is 5 minutes AHEAD of the server.
    final serverNowMs = DateTime.now().millisecondsSinceEpoch - 300000;
    clock.sync(serverNowMs);
    // Lapsed by device time, still live by server time.
    final until = serverNowMs + 45000;
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        serverClockProvider.overrideWithValue(clock),
        matchStreamProvider('m1').overrideWith(
          (ref) => Stream.value(
            _matchWith({
              'me': [
                MatchActiveEffect(
                  kind: MatchEffectKind.comboLock,
                  byUid: 'me',
                  startedAt: 0,
                  expiresAt: until,
                  payload: const {},
                ),
              ],
            }),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(matchStreamProvider('m1'), (_, __) {});
    await container.pump();

    expect(container.read(activeEffectsProvider('m1')).warded, isTrue);
  });

  test('a lapsed combo_lock leaves warded false', () async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1').overrideWith(
          (ref) => Stream.value(
            _matchWith({
              'me': [
                MatchActiveEffect(
                  kind: MatchEffectKind.comboLock,
                  byUid: 'me',
                  startedAt: 0,
                  expiresAt: DateTime.now().millisecondsSinceEpoch - 1000,
                  payload: const {},
                ),
              ],
            }),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(matchStreamProvider('m1'), (_, __) {});
    await container.pump();

    final fx = container.read(activeEffectsProvider('m1'));
    expect(fx.warded, isFalse);
    expect(fx.wardUntil, isNull);
  });
}
