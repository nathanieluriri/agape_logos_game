import 'package:agape_logos_game/core/haptics/haptic_service.dart';
import 'package:agape_logos_game/core/haptics/haptics.dart';
import 'package:agape_logos_game/features/multiplayer/application/match_controller.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_rack.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingHaptics implements HapticService {
  final calls = <String>[];
  @override
  Future<void> init() async {}
  @override
  Future<void> lightImpact() async => calls.add('light');
  @override
  Future<void> mediumImpact() async => calls.add('medium');
  @override
  Future<void> heavyImpact() async => calls.add('heavy');
  @override
  Future<void> gameImpact() async => calls.add('game');
  @override
  Future<void> streakImpact() async => calls.add('streak');
  @override
  Future<void> mistakeImpact() async => calls.add('mistake');
  @override
  Future<void> selectionClick() async => calls.add('selection');
  @override
  Future<void> successPattern() async => calls.add('success');
  @override
  Future<void> tickImpact() async => calls.add('tick');
  @override
  void setMuted(bool muted) {}
}

void main() {
  late _RecordingHaptics haptics;
  late HapticService previous;

  setUp(() {
    previous = Haptics.instance;
    haptics = _RecordingHaptics();
    Haptics.instance = haptics;
  });
  tearDown(() => Haptics.instance = previous);

  // A rack whose only answer is "CAT".
  MatchRack rackWithAnswer() =>
      MatchRack.test(letters: ['C', 'A', 'T'], answers: ['CAT']);

  test('valid word buzzes streakImpact', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(matchPlayControllerProvider.notifier);
    final rack = rackWithAnswer();
    ctrl.syncRack(rack);
    ctrl.touchLetter(0);
    ctrl.touchLetter(1);
    ctrl.touchLetter(2);
    final word = ctrl.endSelection(rack, const {});
    expect(word, 'CAT');
    expect(haptics.calls, contains('streak'));
  });

  test('invalid word buzzes mistakeImpact', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(matchPlayControllerProvider.notifier);
    final rack = rackWithAnswer();
    ctrl.syncRack(rack);
    ctrl.touchLetter(2); // T
    ctrl.touchLetter(0); // C
    final word = ctrl.endSelection(rack, const {});
    expect(word, isNull);
    expect(haptics.calls, contains('mistake'));
  });
}
