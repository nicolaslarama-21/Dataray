import 'package:flutter_test/flutter_test.dart';
import 'package:dataray_app/features/canvas/controllers/canvas_controller.dart';
import 'package:dataray_app/features/canvas/data/canvas_store.dart';
import 'package:dataray_app/features/canvas/data/plotter_font.dart';
import 'package:dataray_app/features/canvas/models/laser_canvas.dart';
import 'package:dataray_app/models/node_event.dart';

class MemoryCanvasStore implements CanvasStore {
  List<Map<String, dynamic>> data = [];
  bool fail = false;
  @override
  Future<List<LaserCanvas>> load() async =>
      data.map(LaserCanvas.fromJson).toList();
  @override
  Future<void> save(List<LaserCanvas> documents) async {
    if (fail) throw StateError('disk error');
    data = documents.map((d) => d.toJson()).toList();
  }
}

NodeEvent trace(Map<String, dynamic> event) =>
    NodeEvent('rx', NodeEventKind.data, {'type': 'canvas', 'id': 1, ...event});
void start(CanvasController c) => c.handle(
    trace({
      'event': 'start',
      'seq': 0,
      'source': 'servo',
      'text': 'HOLA',
      'messageId': 7
    }),
    receiver: true);
void point(CanvasController c, int seq) => c.handle(
    trace({
      'event': 'point',
      'seq': seq,
      'x': .2,
      'y': .4,
      'down': true,
      'dot': true
    }),
    receiver: true);
void main() {
  test('preview is explicitly not a measured trace, and matches plotter grid',
      () {
    final c = CanvasController(MemoryCanvasStore());
    c.handle(
        const NodeEvent('rx', NodeEventKind.data,
            {'type': 'message', 'id': 7, 'text': 'HOLA'}),
        receiver: true);
    expect(c.current!.source, CanvasSource.preview);
    expect(c.current!.state, CanvasState.preview);
    final a = PlotterFont.preview('A');
    expect(a.first.x, 0);
    expect(a.first.y, 1 / 6);
    expect(a.first.dot, true);
    final maximum = PlotterFont.preview('A' * 64);
    expect(maximum.length, lessThan(4096));
    expect(maximum.every((p) => p.x >= 0 && p.x <= 1 && p.y >= 0 && p.y <= 1),
        true);
    c.dispose();
  });
  test('complete commanded trace round trips through saved canvas data',
      () async {
    final store = MemoryCanvasStore();
    final c = CanvasController(store);
    start(c);
    point(c, 1);
    point(c, 2);
    expect(c.canSave, false);
    c.handle(trace({'event': 'end', 'seq': 3, 'complete': true}),
        receiver: true);
    expect(c.current!.source, CanvasSource.servo);
    expect(c.current!.state, CanvasState.complete);
    await c.saveCurrent();
    await c.saveCurrent();
    expect(c.saved.length, 1);
    c.dispose();
    final restored = CanvasController(store);
    await Future<void>.delayed(Duration.zero);
    expect(restored.saved.single.text, 'HOLA');
    expect(restored.saved.single.points.length, 2);
    expect(restored.saved.single.state, CanvasState.complete);
    restored.dispose();
  });
  test('sequence loss and disconnect preserve a visibly incomplete drawing',
      () {
    final c = CanvasController(MemoryCanvasStore());
    start(c);
    point(c, 2);
    c.handle(trace({'event': 'end', 'seq': 3, 'complete': true}),
        receiver: true);
    expect(c.current!.hasGaps, true);
    expect(c.current!.state, CanvasState.interrupted);
    start(c);
    point(c, 1);
    c.handle(const NodeEvent('rx', NodeEventKind.disconnected),
        receiver: false);
    expect(c.current!.state, CanvasState.interrupted);
    expect(c.current!.points.length, 1);
    c.dispose();
  });
  test(
      'foreign, duplicated or malformed coordinates do not become a completed drawing',
      () {
    final c = CanvasController(MemoryCanvasStore());
    start(c);
    point(c, 1);
    point(c, 1);
    c.handle(
        NodeEvent('other', NodeEventKind.data, {
          'type': 'canvas',
          'id': 1,
          'event': 'point',
          'seq': 2,
          'x': .3,
          'y': .4
        }),
        receiver: true);
    expect(c.current!.points.length, 1);
    c.handle(trace({'event': 'point', 'seq': 2, 'x': 2.0, 'y': .4}),
        receiver: true);
    expect(c.current!.state, CanvasState.interrupted);
    expect(c.current!.points.length, 1);
    c.dispose();
  });
  test('failed save keeps existing canvases and does not report success',
      () async {
    final store = MemoryCanvasStore()..fail = true;
    final c = CanvasController(store);
    c.previewMessage('rx', 7, 'HOLA');
    await c.saveCurrent();
    expect(c.error, isNotNull);
    expect(c.notice, isNull);
    expect(c.saved, isEmpty);
    c.dispose();
  });
}
