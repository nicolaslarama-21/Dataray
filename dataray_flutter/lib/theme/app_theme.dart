import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppTheme {
  static Color blue(BuildContext context) =>
      Theme.of(context).colorScheme.primaryContainer;
  static Color mint(BuildContext context) =>
      Theme.of(context).colorScheme.secondaryContainer;
  static Color lavender(BuildContext context) =>
      Theme.of(context).colorScheme.tertiaryContainer;
  static Color ink(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color background(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;
  static ThemeData get light => _build(false);
  static ThemeData get dark => _build(true);

  /// The navigation surface is painted through the bottom inset. On Android
  /// 15+ edge-to-edge can ignore bar colors, so matching the painted surface
  /// and disabling the three-button contrast scrim is also necessary.
  static SystemUiOverlayStyle systemOverlay(ColorScheme colors) {
    final dark = colors.brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: colors.surface,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          dark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    );
  }

  static ThemeData _build(bool dark) {
    final canvas = dark ? const Color(0xff0f1825) : const Color(0xfff5f7fa);
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff2c5f96),
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: dark ? const Color(0xffa5cbf6) : const Color(0xff2c5f96),
      onPrimary: dark ? const Color(0xff123250) : Colors.white,
      secondary: dark ? const Color(0xff9dccbf) : const Color(0xff38685c),
      surface: dark ? const Color(0xff172333) : Colors.white,
      onSurface: dark ? const Color(0xffe3eaf2) : const Color(0xff213044),
      onSurfaceVariant:
          dark ? const Color(0xffafbdce) : const Color(0xff566579),
      primaryContainer:
          dark ? const Color(0xff263f5d) : const Color(0xffe2edf9),
      onPrimaryContainer:
          dark ? const Color(0xffd4e7ff) : const Color(0xff244d79),
      secondaryContainer:
          dark ? const Color(0xff223e36) : const Color(0xffe5f0eb),
      onSecondaryContainer:
          dark ? const Color(0xffc5e8d8) : const Color(0xff315e4e),
      tertiaryContainer:
          dark ? const Color(0xff37364a) : const Color(0xffeeedf5),
      onTertiaryContainer:
          dark ? const Color(0xffe1dff1) : const Color(0xff514b69),
      surfaceContainerLow:
          dark ? const Color(0xff1c293a) : const Color(0xfff7f9fb),
      surfaceContainerHigh:
          dark ? const Color(0xff202e40) : const Color(0xffeef2f6),
      surfaceContainerHighest:
          dark ? const Color(0xff263448) : const Color(0xffe8edf3),
      outline: dark ? const Color(0xff75879c) : const Color(0xff8c9bad),
      outlineVariant: dark ? const Color(0xff334155) : const Color(0xffdce3eb),
    );
    final buttonShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(fontSize: 14, height: 1.4),
          bodySmall: TextStyle(fontSize: 12, height: 1.4),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      appBarTheme: AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: scheme.onSurface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 20,
          systemOverlayStyle: systemOverlay(scheme)),
      navigationBarTheme: NavigationBarThemeData(
          height: 72,
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          indicatorColor: scheme.primaryContainer,
          iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 23,
              color: states.contains(WidgetState.selected)
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant)),
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w600
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? scheme.onSurface
                  : scheme.onSurfaceVariant))),
      cardTheme: CardThemeData(
          color: scheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.outlineVariant))),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outlineVariant)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outlineVariant)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.primary, width: 1.5))),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: buttonShape)),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              side: BorderSide(color: scheme.outlineVariant),
              shape: buttonShape)),
      bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          showDragHandle: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)))),
      dialogTheme: DialogThemeData(
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      popupMenuTheme: PopupMenuThemeData(
          color: scheme.surface,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      dividerTheme: DividerThemeData(
          color: scheme.outlineVariant, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: scheme.inverseSurface,
          contentTextStyle: TextStyle(color: scheme.onInverseSurface),
          shape: buttonShape),
    );
  }
}
