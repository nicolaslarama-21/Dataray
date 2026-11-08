import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dataray_app/controllers/dataray_controller.dart';
import 'package:dataray_app/main.dart';
import 'package:dataray_app/models/station.dart';
import 'widget_test.dart' show FakeRepository, MemoryHistory, tx, rx;

class DiscoveryRepository extends FakeRepository {
  final discovery = Completer<List<Station>>();
  final connectedIds = <String>[];
  final disconnectedIds = <String>[];
  @override
  Future<List<Station>> scan() => discovery.future;
  @override
  Future<Station> connect(Station station) async {
    connectedIds.add(station.id);
    return station;
  }

  @override
  Future<void> disconnect(String id) async {
    disconnectedIds.add(id);
    await super.disconnect(id);
  }
}

void main() {
  testWidgets('device presentation keeps scan, connect and disconnect actions',
      (tester) async {
    final repo = DiscoveryRepository();
    final c = DatarayController(repo, MemoryHistory());
    await tester.pumpWidget(
        ChangeNotifierProvider.value(value: c, child: const DatarayApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar ESP32 cercanos'));
    await tester.pump();
    expect(c.scanning, true);
    expect(find.text('Buscando ESP32…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    repo.discovery.complete([tx, rx]);
    await tester.pumpAndSettle();
    expect(find.text('Disponibles'), findsOneWidget);
    expect(find.text('Fuerte · -50 dBm'), findsOneWidget);
    expect(find.text('Fuerte · -60 dBm'), findsOneWidget);
    await tester.ensureVisible(find.text('Conectar').first);
    await tester.tap(find.text('Conectar').first);
    await tester.pumpAndSettle();
    expect(repo.connectedIds, ['tx']);
    expect(c.nodes.keys, ['tx']);
    expect(find.text('Conectados'), findsOneWidget);
    expect(find.text('Disponibles'), findsOneWidget);
    expect(find.text('DATARAY_TX'), findsOneWidget);
    await tester.ensureVisible(find.text('Desconectar'));
    await tester.tap(find.text('Desconectar'));
    await tester.pumpAndSettle();
    expect(repo.disconnectedIds, ['tx']);
    expect(c.nodes, isEmpty);
    expect(find.text('Conectados'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });
}
