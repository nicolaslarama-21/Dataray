import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../models/node_event.dart';
import '../data/canvas_store.dart';
import '../data/plotter_font.dart';
import '../models/laser_canvas.dart';

class CanvasController extends ChangeNotifier {
  CanvasController(this.store) {
    unawaited(_load());
  }
  final CanvasStore store;
  final _ready = Completer<void>();
  LaserCanvas? current;
  List<LaserCanvas> saved = [];
  String? error, notice;
  bool saving = false, _disposed = false;
  Timer? _timeout;
  int _serial = 0;
  bool get recording => current?.state == CanvasState.recording;
  bool get canSave =>
      current != null && current!.points.isNotEmpty && !recording && !saving;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _load() async {
    try {
      final loaded = await store.load();
      if (!_disposed) saved = loaded;
    } on MissingPluginException {
      /* No native storage in desktop/widget previews. */
    } catch (_) {
      error = 'No pudimos abrir los lienzos guardados.';
    }
    _ready.complete();
    _notify();
  }

  void previewMessage(String stationId, int id, String text) {
    if (recording || text.isEmpty || text.length > 64) return;
    current = LaserCanvas(
        id: '${DateTime.now().microsecondsSinceEpoch}-${++_serial}',
        text: text,
        stationId: stationId,
        messageId: id,
        time: DateTime.now(),
        source: CanvasSource.preview,
        state: CanvasState.preview,
        points: PlotterFont.preview(text));
    error = null;
    notice = null;
    _notify();
  }

  void _armTimeout() {
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 12), () {
      if (recording) {
        current = current!.copy(state: CanvasState.interrupted, hasGaps: true);
        error = 'Se interrumpió el trazado. Puedes guardar la parte recibida.';
        _notify();
      }
    });
  }

  void handle(NodeEvent event, {required bool receiver}) {
    if (event.kind == NodeEventKind.disconnected) {
      if (recording && current!.stationId == event.stationId) {
        _timeout?.cancel();
        current = current!.copy(state: CanvasState.interrupted, hasGaps: true);
        error = 'El módulo se desconectó. El lienzo recibido sigue aquí.';
        _notify();
      }
      return;
    }
    if (event.kind != NodeEventKind.data || !receiver) return;
    final data = event.data;
    if (data['type'] == 'message' &&
        data['text'] is String &&
        data['id'] is int) {
      previewMessage(
          event.stationId, data['id'] as int, data['text'] as String);
      return;
    }
    if (data['type'] != 'canvas') return;
    final id = data['id'], sequence = data['seq'];
    if (id is! int || sequence is! int || sequence < 0) return;
    if (data['event'] == 'start') {
      final text = data['text'];
      if (text is! String ||
          text.length > 64 ||
          sequence != 0 ||
          !['servo', 'tracker'].contains(data['source'])) {
        return;
      }
      _timeout?.cancel();
      current = LaserCanvas(
          id: '${DateTime.now().microsecondsSinceEpoch}-${++_serial}',
          text: text,
          stationId: event.stationId,
          messageId: data['messageId'] is int ? data['messageId'] as int : null,
          captureId: id,
          time: DateTime.now(),
          source: data['source'] == 'servo'
              ? CanvasSource.servo
              : CanvasSource.tracker,
          state: CanvasState.recording,
          points: const []);
      error = null;
      notice = null;
      _armTimeout();
      _notify();
      return;
    }
    final canvas = current;
    if (canvas == null ||
        !recording ||
        canvas.captureId != id ||
        canvas.stationId != event.stationId ||
        sequence <= canvas.lastSequence) {
      return;
    }
    final gap = sequence != canvas.lastSequence + 1;
    if (data['event'] == 'point') {
      try {
        if (canvas.points.length + (gap ? 2 : 1) > 4096) {
          throw const FormatException();
        }
        final point = TracePoint.fromJson(data);
        current = canvas.copy(
            points: List.unmodifiable([
              ...canvas.points,
              if (gap) TracePoint(point.x, point.y, down: false),
              point
            ]),
            lastSequence: sequence,
            hasGaps: canvas.hasGaps || gap);
        _armTimeout();
      } catch (_) {
        _timeout?.cancel();
        current = canvas.copy(state: CanvasState.interrupted, hasGaps: true);
        error = 'El trazado llegó incompleto o superó el límite de puntos.';
      }
    } else if (data['event'] == 'end') {
      _timeout?.cancel();
      final complete = data['complete'] == true && !canvas.hasGaps && !gap;
      current = canvas.copy(
          state: complete ? CanvasState.complete : CanvasState.interrupted,
          hasGaps: canvas.hasGaps || gap,
          lastSequence: sequence);
    }
    _notify();
  }

  Future<void> saveCurrent() async {
    if (!canSave) return;
    final snapshot = current!;
    saving = true;
    error = null;
    notice = null;
    _notify();
    await _ready.future;
    final updated = [snapshot, ...saved.where((c) => c.id != snapshot.id)]
        .take(20)
        .toList();
    try {
      await store.save(updated);
      saved = updated;
      notice = 'Lienzo guardado en este teléfono.';
    } on MissingPluginException {
      error = 'Guardar lienzos requiere la app instalada en Android o iPhone.';
    } catch (_) {
      error = 'No pudimos guardar el lienzo. Inténtalo otra vez.';
    } finally {
      saving = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timeout?.cancel();
    super.dispose();
  }
}
