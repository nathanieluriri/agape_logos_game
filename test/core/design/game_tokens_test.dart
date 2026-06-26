import 'package:agape_logos_game/core/design/tokens/colors.dart';
import 'package:agape_logos_game/core/design/tokens/sizing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('game color tokens are defined and distinct from pond chrome', () {
    expect(AppColors.tileBlue, isA<Color>());
    expect(AppColors.tileBlueText, isA<Color>());
    expect(AppColors.slotEmpty, isA<Color>());
    expect(AppColors.wheelBase, isA<Color>());
    expect(AppColors.connectLine, AppColors.tileBlue);
    expect(AppColors.comboBannerStart, isNot(AppColors.comboBannerEnd));
  });

  test('game sizing tokens are positive', () {
    expect(AppSizing.wheelDiameter, greaterThan(0));
    expect(AppSizing.wheelNode, greaterThan(0));
    expect(AppSizing.boardTile, greaterThan(0));
    expect(AppSizing.boardTileGap, greaterThanOrEqualTo(0));
  });
}
