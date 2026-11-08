enum CanvasSource { preview, servo, tracker }

enum CanvasState { preview, recording, complete, interrupted }

class TracePoint {
  const TracePoint(this.x, this.y, {this.down = true, this.dot = false});
  final double x, y;
  final bool down, dot;
  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'down': down, 'dot': dot};
  factory TracePoint.fromJson(Map<String, dynamic> j) {
    final x = (j['x'] as num).toDouble(), y = (j['y'] as num).toDouble();
    if (!x.isFinite || !y.isFinite || x < 0 || x > 1 || y < 0 || y > 1) {
      throw const FormatException('Punto fuera del lienzo');
    }
    return TracePoint(x, y,
        down: j['down'] as bool? ?? true, dot: j['dot'] as bool? ?? false);
  }
}

class LaserCanvas {
  const LaserCanvas(
      {required this.id,
      required this.text,
      required this.stationId,
      required this.time,
      required this.source,
      required this.state,
      required this.points,
      this.messageId,
      this.captureId,
      this.lastSequence = 0,
      this.hasGaps = false});
  final String id, text, stationId;
  final DateTime time;
  final CanvasSource source;
  final CanvasState state;
  final List<TracePoint> points;
  final int? messageId, captureId;
  final int lastSequence;
  final bool hasGaps;
  String get sourceLabel => switch (source) {
        CanvasSource.preview => 'Vista previa',
        CanvasSource.servo => 'Trayectoria del brazo',
        CanvasSource.tracker => 'Seguimiento externo'
      };
  String get stateLabel => switch (state) {
        CanvasState.preview => 'Aún no dibujado',
        CanvasState.recording => 'Dibujando…',
        CanvasState.complete => 'Trazado recibido',
        CanvasState.interrupted => 'Trazado incompleto'
      };
  LaserCanvas copy(
          {List<TracePoint>? points,
          CanvasState? state,
          int? lastSequence,
          bool? hasGaps}) =>
      LaserCanvas(
          id: id,
          text: text,
          stationId: stationId,
          time: time,
          source: source,
          state: state ?? this.state,
          points: points ?? this.points,
          messageId: messageId,
          captureId: captureId,
          lastSequence: lastSequence ?? this.lastSequence,
          hasGaps: hasGaps ?? this.hasGaps);
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'stationId': stationId,
        'time': time.toIso8601String(),
        'source': source.name,
        'state': state.name,
        'points': points.map((p) => p.toJson()).toList(),
        'messageId': messageId,
        'captureId': captureId,
        'lastSequence': lastSequence,
        'hasGaps': hasGaps
      };
  factory LaserCanvas.fromJson(Map<String, dynamic> j) {
    final raw = j['points'] as List;
    if (raw.length > 4096 || (j['text'] as String).length > 64) {
      throw const FormatException('Lienzo demasiado grande');
    }
    return LaserCanvas(
        id: j['id'] as String,
        text: j['text'] as String,
        stationId: j['stationId'] as String,
        time: DateTime.parse(j['time'] as String),
        source: CanvasSource.values.byName(j['source'] as String),
        state: CanvasState.values.byName(j['state'] as String),
        points: List.unmodifiable(raw.map(
            (p) => TracePoint.fromJson(Map<String, dynamic>.from(p as Map)))),
        messageId: j['messageId'] as int?,
        captureId: j['captureId'] as int?,
        lastSequence: j['lastSequence'] as int? ?? 0,
        hasGaps: j['hasGaps'] as bool? ?? false);
  }
}
