import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dataray_app/main.dart';
import 'package:dataray_app/controllers/dataray_controller.dart';
import 'package:dataray_app/models/node_event.dart';
import 'widget_test.dart' show FakeRepository, MemoryHistory, tx, rx;

void main() {
  testWidgets('small mobile screen with large text keeps all tabs usable',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
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
      'robotBusy': false,
      'packets': 12,
    }));
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: c,
        child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
            child: const DatarayApp())));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final label in ['Chat', 'Pruebas', 'Historial']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });
}
