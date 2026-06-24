// test/core/design/typography_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/core/design/tokens/typography.dart';

void main() {
  test('wordmark is a large serif style', () {
    expect(AppTypography.wordmark.fontSize, 40);
    expect(AppTypography.wordmark.fontFamily, 'ZenSerif');
    expect(AppTypography.wordmark.fontFamilyFallback, contains('serif'));
  });
  test('numeral is a serif fraction style', () {
    expect(AppTypography.numeral.fontSize, 30);
    expect(AppTypography.numeral.fontWeight, FontWeight.w700);
  });
}
