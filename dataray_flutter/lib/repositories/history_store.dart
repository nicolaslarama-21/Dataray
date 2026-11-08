import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/test_result.dart';

abstract class HistoryStore {
  Future<List<TestResult>> load();
  Future<void> save(List<TestResult> results);
}

/// JSON in the application's private directory, via native mobile channels.
class MobileHistoryStore implements HistoryStore {
  static const _channel = MethodChannel('dataray/history');
  @override
  Future<List<TestResult>> load() async {
    final source = await _channel.invokeMethod<String>('read');
    if (source == null || source.isEmpty) return [];
    return (jsonDecode(source) as List)
        .map((e) => TestResult.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> save(List<TestResult> results) => _channel.invokeMethod<void>(
      'write', jsonEncode(results.map((e) => e.toJson()).toList()));
}
