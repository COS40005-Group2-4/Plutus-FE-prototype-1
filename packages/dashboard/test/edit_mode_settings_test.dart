import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard/dashboard.dart';

void main() {
  test('EditModeSettings swapHighlightColor defaults to legacy green', () {
    final EditModeSettings settings = EditModeSettings();
    expect(settings.swapHighlightColor, const Color(0xFF4CAF50));
  });

  test('EditModeSettings passes a custom swapHighlightColor through', () {
    final EditModeSettings settings =
        EditModeSettings(swapHighlightColor: const Color(0xFFC9970F));
    expect(settings.swapHighlightColor, const Color(0xFFC9970F));
  });
}
