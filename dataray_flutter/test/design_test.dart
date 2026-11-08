import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dataray_app/controllers/dataray_controller.dart';
import 'package:dataray_app/main.dart';
import 'package:dataray_app/models/station.dart';
import 'package:dataray_app/models/node_event.dart';
import 'package:dataray_app/navigation/tab_history.dart';
import 'widget_test.dart' show FakeRepository, MemoryHistory, tx, rx;

void main() {
  test('back follows actual tab visits without adding another visit', () {
    final tabs = TabHistory();
    tabs.select(1);
    tabs.select(2);
    tabs.select(2);
    tabs.select(3);
    expect(tabs.back(), true);
    expect(tabs.current, 2);
    tabs.back();
    expect(tabs.current, 1);
    tabs.back();
    expect(tabs.current, 0);
    expect(tabs.back(), false);
  });
  testWidgets('test shortcut stays visible while a long module list scrolls',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = DatarayController(FakeRepository(), MemoryHistory());
    // A deliberately long visual list, independent of the current two-role connection policy.
    for (var i = 0; i < 12; i++) {
      c.nodes['module-$i'] =
          Station(id: 'module-$i', name: 'Módulo $i', rssi: -50);
    }
    await tester.pumpWidget(
        ChangeNotifierProvider.value(value: c, child: const DatarayApp()));
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('home-test-button'));
    final before = tester.getRect(button);
    await tester.drag(find.byKey(const ValueKey('home-modules-scroll')),
        const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(tester.getRect(button), before);
    expect(button.hitTestable(), findsOneWidget);
    expect(find.textContaining('/2 BLE'), findsNothing);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Prueba cómo viaja la luz'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });
  testWidgets('context help and guide open and close without losing the tab',
      (tester) async {
    final c = DatarayController(FakeRepository(), MemoryHistory());
    await tester.pumpWidget(
        ChangeNotifierProvider.value(value: c, child: const DatarayApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pruebas'));
    await tester.pumpAndSettle();
    expect(find.textContaining('La prueba envía un mensaje conocido.'),
        findsNothing);
    await tester.tap(find.byTooltip('Ayuda: ¿Llegó bien el mensaje?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('La prueba envía un mensaje conocido.'),
        findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ayuda y consejos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cómo hacer una prueba'));
    await tester.pumpAndSettle();
    expect(find.text('Una prueba, paso a paso'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar guía'));
    await tester.pumpAndSettle();
    expect(find.text('Prueba cómo viaja la luz'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });
  testWidgets(
      'back returns to the previous tab and Android exit needs two presses',
      (tester) async {
    var exits = 0;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.pop') exits++;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    final c = DatarayController(FakeRepository(), MemoryHistory());
    await tester.pumpWidget(
        ChangeNotifierProvider.value(value: c, child: const DatarayApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pruebas'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Volver a la pestaña anterior'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Conecta un módulo desde Inicio.'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Módulos'), findsOneWidget);
    expect(exits, 0);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Presiona atrás otra vez para salir'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(exits, 0);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(exits, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });
  testWidgets('connected screens render at mobile size', (tester) async {
    if (const bool.fromEnvironment('CAPTURE_DESIGN')) {
      await tester.runAsync(() async {
        final root = Platform.environment['FLUTTER_ROOT']!;
        final fonts = '$root/bin/cache/artifacts/material_fonts';
        final roboto = await File('$fonts/roboto-regular.ttf').readAsBytes();
        await ui.loadFontFromList(roboto, fontFamily: 'Ahem');
        await ui.loadFontFromList(roboto, fontFamily: 'Roboto');
        await ui.loadFontFromList(
            await File('$fonts/materialicons-regular.otf').readAsBytes(),
            fontFamily: 'MaterialIcons');
      });
    }
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeRepository();
    final c = DatarayController(repository, MemoryHistory());
    await c.connect(tx);
    await c.connect(rx);
    repository.stream.add(const NodeEvent('rx', NodeEventKind.data, {
      'type': 'status',
      'adc': 2048,
      'threshold': 1800,
      'light': true,
      'packets': 12,
      'robotBusy': false
    }));
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: c,
        child: const RepaintBoundary(
            key: ValueKey('design-preview'), child: DatarayApp())));
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      if (!const bool.fromEnvironment('CAPTURE_DESIGN')) return;
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('design-preview')));
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('.validation/previews').create(recursive: true);
        await File('.validation/previews/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    expect(find.byType(Image), findsNothing);
    await capture('home');
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Pruebas'));
    await tester.pumpAndSettle();
    await capture('tests');
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Ayuda: ¿Llegó bien el mensaje?'));
    await tester.pumpAndSettle();
    await capture('help');
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ayuda y consejos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apariencia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modo oscuro'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(NavigationBar))).brightness,
        Brightness.dark);
    await capture('tests-dark');
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Ayuda: ¿Llegó bien el mensaje?'));
    await tester.pumpAndSettle();
    await capture('help-dark');
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    await capture('home-dark');
    for (final label in ['Chat', 'Historial']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      await capture('${label.toLowerCase()}-dark');
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.byTooltip('Ayuda y consejos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apariencia'));
    await tester.pumpAndSettle();
    await capture('appearance-dark');
    await tester.tap(find.text('Modo claro'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(NavigationBar))).brightness,
        Brightness.light);
    expect(find.text('Aquí estarán tus pruebas'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });
}
