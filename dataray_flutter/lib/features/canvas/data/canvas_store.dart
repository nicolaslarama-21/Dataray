import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/laser_canvas.dart';

abstract class CanvasStore {
  Future<List<LaserCanvas>> load();
  Future<void> save(List<LaserCanvas> documents);
}

class MobileCanvasStore implements CanvasStore {
  static const channel = MethodChannel('dataray/canvases');
  @override
  Future<List<LaserCanvas>> load() async {
    final source = await channel.invokeMethod<String>('read');
    if (source == null || source.isEmpty) return [];
    final raw = jsonDecode(source) as List;
    if (raw.length > 20) throw const FormatException('Demasiados lienzos');
    return raw
        .map((j) => LaserCanvas.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
  }

  @override
  Future<void> save(List<LaserCanvas> documents) => channel.invokeMethod<void>(
      'write', jsonEncode(documents.map((d) => d.toJson()).toList()));
}
