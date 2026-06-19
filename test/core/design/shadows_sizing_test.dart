// test/core/design/shadows_sizing_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/core/design/tokens/shadows.dart';
import 'package:agape_logos_game/core/design/tokens/sizing.dart';

void main() {
  test('pad shadow is a non-empty soft shadow', () {
    expect(AppShadows.pad, isNotEmpty);
    expect(AppShadows.pad.first.blurRadius, greaterThan(0));
  });
  test('sizing exposes a centered-stage max width and pad sizes', () {
    expect(AppSizing.stageMaxWidth, 460);
    expect(AppSizing.playPad, 180);
    expect(AppSizing.secondaryPad, 104);
  });
}
