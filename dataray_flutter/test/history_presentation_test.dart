import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dataray_app/main.dart';
import 'package:dataray_app/controllers/dataray_controller.dart';
import 'package:dataray_app/models/test_result.dart';
import 'widget_test.dart' show FakeRepository, MemoryHistory;

final records = [
  TestResult(
      id: 3,
      time: DateTime(2026, 10, 29, 16, 30),
      distance: 2.5,
      bits: 184,
      errors: 0,
      crcOk: true,
      stationId: 'receiver'),
  TestResult(
      id: 2,
      time: DateTime(2026, 10, 29, 15, 20),
      distance: 5,
      bits: 184,
      errors: 1,
      crcOk: false,
      stationId: 'receiver'),
  TestResult(
      id: 1,
      time: DateTime(2026, 10, 28, 12, 10),
      distance: 1,
      bits: 184,
      errors: 0,
      crcOk: true,
      stationId: 'receiver'),
];
Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_DESIGN')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('history-preview')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('.validation/previews').create(recursive: true);
    await File('.validation/previews/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  testWidgets(
      'history groups existing results, shows detail and respects system insets',
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
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    final store = MemoryHistory()..records = records;
    final c = DatarayController(FakeRepository(), store);
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: c,
        child: const RepaintBoundary(
            key: ValueKey('history-preview'), child: DatarayApp())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.text('Pruebas guardadas'), findsOneWidget);
    expect(find.text('29/10/2026'), findsOneWidget);
    expect(find.text('28/10/2026'), findsOneWidget);
    expect(c.history.map((r) => r.id).toList(), [3, 2, 1]);
    expect(tester.getRect(find.byType(NavigationBar)).bottom, 844);
    expect(tester.getSize(find.byType(NavigationBar)).height, 96);
    await capture(tester, 'history-light');
    await tester.tap(find.text('16:30'));
    await tester.pumpAndSettle();
    expect(find.text('Resultado de la prueba'), findsOneWidget);
    expect(find.text('2.5 m'), findsNWidgets(2));
    await capture(tester, 'history-detail-light');
    await tester.tap(find.byTooltip('Cerrar resultado'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ayuda y consejos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apariencia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modo oscuro'));
    await tester.pumpAndSettle();
    final darkColors =
        Theme.of(tester.element(find.byType(NavigationBar))).colorScheme;
    expect(tester.widget<Text>(find.text('Pruebas guardadas')).style?.color,
        darkColors.onSurface);
    await capture(tester, 'history-dark');
    await tester.tap(find.text('16:30'));
    await tester.pumpAndSettle();
    await capture(tester, 'history-detail-dark');
    await tester.tap(find.byTooltip('Cerrar resultado'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(320, 720);
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: c,
        child: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.4)),
            child: DatarayApp())));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(c.history.map((r) => r.id).toList(), [3, 2, 1]);
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });
}
