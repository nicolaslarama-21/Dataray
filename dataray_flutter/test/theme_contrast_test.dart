import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dataray_app/theme/app_theme.dart';

double contrast(Color a, Color b) {
  final first = a.computeLuminance(), second = b.computeLuminance();
  return first > second
      ? (first + .05) / (second + .05)
      : (second + .05) / (first + .05);
}

void main() {
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    test('${theme.brightness.name} theme keeps text and controls readable', () {
      final colors = theme.colorScheme;
      for (final pair in [
        (colors.onSurface, colors.surface),
        (colors.onSurface, theme.scaffoldBackgroundColor),
        (colors.onSurface, colors.surfaceContainerHighest),
        (colors.onSurfaceVariant, colors.surface),
        (colors.onPrimary, colors.primary),
        (colors.onPrimaryContainer, colors.primaryContainer),
        (colors.onSecondaryContainer, colors.secondaryContainer),
        (colors.primary, colors.surface),
        (
          theme.appBarTheme.foregroundColor!,
          theme.appBarTheme.backgroundColor!
        ),
      ]) {
        expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5),
            reason: '${theme.brightness.name}: ${pair.$1} on ${pair.$2}');
      }
      expect(colors.surface, isNot(theme.scaffoldBackgroundColor));
      expect(theme.appBarTheme.backgroundColor, theme.scaffoldBackgroundColor);
      final overlay = AppTheme.systemOverlay(colors);
      expect(overlay.systemNavigationBarColor,
          theme.navigationBarTheme.backgroundColor);
      expect(overlay.systemNavigationBarContrastEnforced, false);
      expect(
          overlay.statusBarIconBrightness,
          theme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark);
    });
  }
}
