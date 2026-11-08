import 'package:flutter/material.dart';
import '../models/laser_canvas.dart';

class LaserCanvasView extends StatelessWidget {
  const LaserCanvasView({required this.document, super.key});
  final LaserCanvas? document;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
        label: document == null
            ? 'Lienzo vacío'
            : '${document!.sourceLabel}: ${document!.text}',
        child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(
                key: const ValueKey('laser-canvas'),
                painter: LaserCanvasPainter(document,
                    background: colors.surface,
                    grid: colors.outlineVariant.withValues(alpha: .4),
                    laser: colors.brightness == Brightness.dark
                        ? const Color(0xffff8a80)
                        : const Color(0xffc62828)),
                child: document == null
                    ? Center(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('El dibujo aparecerá aquí',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: colors.onSurfaceVariant))))
                    : const SizedBox.expand())));
  }
}

class LaserCanvasPainter extends CustomPainter {
  LaserCanvasPainter(this.document,
      {required this.background, required this.grid, required this.laser});
  final LaserCanvas? document;
  final Color background, grid, laser;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final dots = Paint()..color = grid;
    for (double x = 12; x < size.width; x += 24) {
      for (double y = 12; y < size.height; y += 24) {
        canvas.drawCircle(Offset(x, y), .65, dots);
      }
    }
    final points = document?.points ?? const <TracePoint>[];
    final paint = Paint()
      ..color = laser
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    Offset position(TracePoint p) =>
        Offset(12 + p.x * (size.width - 24), 12 + p.y * (size.height - 24));
    TracePoint? previous;
    final radius = ((size.width - 24) / 46 * .32).clamp(1.5, 3.5).toDouble();
    for (final point in points) {
      if (point.down) {
        if (point.dot) {
          canvas.drawCircle(position(point), radius, paint);
        } else if (previous != null && previous.down && !previous.dot) {
          canvas.drawLine(position(previous), position(point), paint);
        } else {
          canvas.drawCircle(position(point), 1.5, paint);
        }
      }
      previous = point;
    }
  }

  @override
  bool shouldRepaint(LaserCanvasPainter old) =>
      old.document != document ||
      old.background != background ||
      old.grid != grid ||
      old.laser != laser;
}
