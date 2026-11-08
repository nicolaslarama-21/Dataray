import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dataray_app/theme/appearance_controller.dart';

class MemoryAppearanceStore implements AppearanceStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String next) async {
    value = next;
  }
}

class DelayedAppearanceStore extends MemoryAppearanceStore {
  final pending = Completer<String?>();
  @override
  Future<String?> read() => pending.future;
}

void main() {
  test('appearance choice is saved and restored on reopening', () async {
    final store = MemoryAppearanceStore();
    final first = AppearanceController(store);
    await Future<void>.delayed(Duration.zero);
    first.select(ThemeMode.dark);
    await Future<void>.delayed(Duration.zero);
    expect(store.value, 'dark');
    first.dispose();
    final reopened = AppearanceController(store);
    await Future<void>.delayed(Duration.zero);
    expect(reopened.mode, ThemeMode.dark);
    reopened.dispose();
  });
  test('a late saved preference cannot overwrite a new choice', () async {
    final store = DelayedAppearanceStore();
    final controller = AppearanceController(store);
    controller.select(ThemeMode.dark);
    store.pending.complete('light');
    await Future<void>.delayed(Duration.zero);
    expect(controller.mode, ThemeMode.dark);
    expect(store.value, 'dark');
    controller.dispose();
  });
}
