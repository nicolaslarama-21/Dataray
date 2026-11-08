import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dataray_app/controllers/dataray_controller.dart';
import 'package:dataray_app/features/canvas/data/plotter_font.dart';
import 'package:dataray_app/features/canvas/models/laser_canvas.dart';
import 'package:dataray_app/features/canvas/widgets/laser_canvas_view.dart';
import 'package:dataray_app/main.dart';
import 'package:dataray_app/models/node_event.dart';
import 'widget_test.dart' show FakeRepository, MemoryHistory, rx, tx;
import 'canvas_controller_test.dart' show MemoryCanvasStore;

void main() {
  testWidgets(
      'chat presents received text, live canvas, saved gallery and compact keyboard layout',
      (tester) async {
    if (const bool.fromEnvironment('CAPTURE_DESIGN')) {
      await tester.runAsync(() async {
        final fonts =
            '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
        final bytes = await File('$fonts/roboto-regular.ttf').readAsBytes();
        await ui.loadFontFromList(bytes, fontFamily: 'Ahem');
        await ui.loadFontFromList(bytes, fontFamily: 'Roboto');
        await ui.loadFontFromList(
            await File('$fonts/materialicons-regular.otf').readAsBytes(),
            fontFamily: 'MaterialIcons');
      });
    }
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final repository = FakeRepository(), store = MemoryCanvasStore();
    final c =
        DatarayController(repository, MemoryHistory(), canvasStore: store);
    await c.connect(rx);
    await c.connect(tx);
    repository.stream.add(const NodeEvent('rx', NodeEventKind.data,
        {'type': 'message', 'id': 7, 'text': 'HOLA'}));
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: c,
        child: const RepaintBoundary(
            key: ValueKey('canvas-preview'), child: DatarayApp())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.text('Mensaje de este lienzo: HOLA'), findsOneWidget);
    expect(find.text('Vista previa'), findsOneWidget);
    expect(find.byType(LaserCanvasView), findsOneWidget);
    await tester.tap(find.byTooltip('Guardar vista previa'));
    await tester.pumpAndSettle();
    expect(store.data.length, 1);
    await tester.tap(find.byTooltip('Lienzos guardados'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('HOLA').last);
    await tester.pumpAndSettle();
    expect(find.text('Mensaje de este lienzo'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    repository.stream.add(const NodeEvent('rx', NodeEventKind.data, {
      'type': 'canvas',
      'event': 'start',
      'seq': 0,
      'id': 9,
      'source': 'servo',
      'messageId': 7,
      'text': 'HOLA'
    }));
    var seq = 0;
    for (final p in PlotterFont.preview('HOLA')) {
      repository.stream.add(NodeEvent('rx', NodeEventKind.data, {
        'type': 'canvas',
        'event': 'point',
        'seq': ++seq,
        'id': 9,
        ...p.toJson()
      }));
    }
    repository.stream.add(NodeEvent('rx', NodeEventKind.data, {
      'type': 'canvas',
      'event': 'end',
      'seq': ++seq,
      'id': 9,
      'complete': true
    }));
    await tester.pumpAndSettle();
    expect(find.text('Trayectoria del brazo'), findsOneWidget);
    expect(c.canvases.current!.state, CanvasState.complete);
    if (const bool.fromEnvironment('CAPTURE_DESIGN')) {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('canvas-preview')));
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('.validation/previews/chat-canvas.png')
            .writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(find.text('Ver lienzo'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });
}
