// test/core/design/colors_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/core/design/tokens/colors.dart';

void main() {
  test('pond palette stops are defined and opaque', () {
    expect(AppColors.pondTop, const Color(0xFF1FB19C));
    expect(AppColors.pondDeep, const Color(0xFF064F57));
    expect(AppColors.lilyGreenLight, const Color(0xFF84D8AD));
    expect(AppColors.lilyTealDeep, const Color(0xFF147F78));
    expect(AppColors.progressFillStart, const Color(0xFF94C92B));
    expect(AppColors.wordmark, const Color(0xFFFDFBF3));
  });
}
