// test/core/design/gradients_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/core/design/tokens/gradients.dart';
import 'package:agape_logos_game/core/design/tokens/colors.dart';

void main() {
  test('pond gradient runs from top glow to deep water', () {
    expect(AppGradients.pond.colors.first, AppColors.pondTop);
    expect(AppGradients.pond.colors.last, AppColors.pondDeep);
  });
  test('lily green is a radial gradient with three stops', () {
    expect(AppGradients.lilyGreen, isA<RadialGradient>());
    expect(AppGradients.lilyGreen.colors.length, 3);
  });
}
