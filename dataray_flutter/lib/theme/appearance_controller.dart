import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract class AppearanceStore {
  Future<String?> read();
  Future<void> write(String value);
}

class MobileAppearanceStore implements AppearanceStore {
  static const channel = MethodChannel('dataray/settings');
  @override
  Future<String?> read() => channel.invokeMethod<String>('readTheme');
  @override
  Future<void> write(String value) =>
      channel.invokeMethod<void>('writeTheme', value);
}

class AppearanceController extends ChangeNotifier {
  AppearanceController(this.store) {
    unawaited(_restore());
  }
  final AppearanceStore store;
  ThemeMode mode = ThemeMode.light;
  bool _selected = false, _disposed = false;
  Future<void> _writes = Future.value();
  Future<void> _restore() async {
    try {
      final stored = await store.read();
      if (!_selected && !_disposed && stored != null) {
        mode = stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
        notifyListeners();
      }
    } on MissingPluginException {
      /* Preview/test platforms have no native settings. */
    } on PlatformException {
      /* Use the current theme if storage is unavailable. */
    }
  }

  void select(ThemeMode value) {
    _selected = true;
    if (mode == value) return;
    mode = value;
    notifyListeners();
    _writes = _writes.then((_) async {
      try {
        await store.write(value == ThemeMode.dark ? 'dark' : 'light');
      } on MissingPluginException {
        /* In-memory appearance is still usable. */
      } on PlatformException {
        /* Keep appearance usable even if saving fails. */
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
