import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dataray_app/main.dart';
import 'package:dataray_app/controllers/dataray_controller.dart';
import 'package:dataray_app/core/wire_protocol.dart';
import 'package:dataray_app/models/node_event.dart';
import 'package:dataray_app/models/station.dart';
import 'package:dataray_app/models/test_result.dart';
import 'package:dataray_app/models/chat_message.dart';
import 'package:dataray_app/repositories/dataray_repository.dart';
import 'package:dataray_app/repositories/history_store.dart';

class FakeRepository implements DatarayRepository {
  final stream = StreamController<NodeEvent>.broadcast(sync: true);
  final commands = <Map<String, dynamic>>[];
  bool fail = false;
  @override
  Stream<NodeEvent> get events => stream.stream;
  @override
  Future<List<Station>> scan() async => [];
  @override
  Future<Station> connect(Station station) async => station;
  @override
  Future<void> disconnect(String id) async =>
      stream.add(NodeEvent(id, NodeEventKind.disconnected));
  @override
  Future<void> command(String id, Map<String, dynamic> command) async {
    if (fail) throw StateError('BLE lost');
    commands.add(command);
  }

  @override
  Future<void> dispose() => stream.close();
}

class MemoryHistory implements HistoryStore {
  List<TestResult> records = [];
  @override
  Future<List<TestResult>> load() async => records;
  @override
  Future<void> save(List<TestResult> results) async {
    records = results;
  }
}

const tx = Station(
    id: 'tx', name: 'DATARAY_TX', rssi: -50, role: StationRole.transmitter);
const rx = Station(
    id: 'rx', name: 'DATARAY_RX', rssi: -60, role: StationRole.receiver);
void main() {
  test('NDJSON accepts fragmented and grouped notifications', () {
    final decoder = LineDecoder();
    expect(decoder.add('{"type":"mes'.codeUnits), isEmpty);
    final events =
        decoder.add('sage","text":"HOLA"}\n{"type":"status"}\n'.codeUnits);
    expect(events.length, 2);
    expect(events.first['text'], 'HOLA');
  });
  test('oversized line is discarded and the next event survives', () {
    final decoder = LineDecoder();
    expect(decoder.add(('x' * 600).codeUnits), isEmpty);
    expect(decoder.add('\n{"type":"status"}\n'.codeUnits).single['type'],
        'status');
  });
  test('normalization enforces the optical alphabet and byte limit', () {
    expect(() => normalizeMessage(' ¡hola! '), throwsFormatException);
    expect(normalizeMessage('niño áéíóú'), 'NINO AEIOU');
    expect(() => normalizeMessage('😀'), throwsFormatException);
    expect(() => normalizeMessage('A' * 65), throwsFormatException);
  });
  test('write failure keeps a failed message and reports failure', () async {
    final repository = FakeRepository();
    final c = DatarayController(repository, MemoryHistory());
    await c.connect(tx);
    repository.fail = true;
    expect(await c.send('hola'), false);
    expect(c.messages.single.state, MessageState.failed);
    expect(c.error, contains('BLE lost'));
    c.dispose();
  });
  test('emission is confirmed only by the matching transmitter event',
      () async {
    final repository = FakeRepository();
    final c = DatarayController(repository, MemoryHistory());
    await c.connect(tx);
    await c.send('hola');
    expect(c.messages.single.state, MessageState.queued);
    final id = c.messages.single.id;
    repository.stream
        .add(NodeEvent('other', NodeEventKind.data, {'type': 'tx', 'id': id}));
    expect(c.messages.single.state, MessageState.queued);
    repository.stream
        .add(NodeEvent('tx', NodeEventKind.data, {'type': 'tx', 'id': id}));
    expect(c.messages.single.state, MessageState.transmitted);
    c.dispose();
  });
  test('test uses receiver bits, ignores stale ids, persists once', () async {
    final repository = FakeRepository();
    final store = MemoryHistory();
    final c = DatarayController(repository, store);
    await c.connect(tx);
    await c.connect(rx);
    c.distance = 2.5;
    await c.startTest();
    final id = repository.commands.last['id'] as int;
    repository.stream.add(NodeEvent('rx', NodeEventKind.data, {
      'type': 'test',
      'id': id - 1,
      'bits': 184,
      'errors': 1,
      'crcOk': false
    }));
    expect(c.testing, true);
    expect(c.latestTest, isNull);
    repository.stream.add(NodeEvent('rx', NodeEventKind.data,
        {'type': 'test', 'id': id, 'bits': 184, 'errors': 1, 'crcOk': false}));
    expect(c.testing, false);
    expect(c.latestTest!.ber, 1 / 184);
    expect(c.latestTest!.distance, 2.5);
    await c.saveTest();
    await c.saveTest();
    expect(store.records.length, 1);
    c.dispose();
  });
  test('disconnect ends pending work without a fabricated result', () async {
    final repository = FakeRepository();
    final c = DatarayController(repository, MemoryHistory());
    await c.connect(tx);
    await c.connect(rx);
    await c.startTest();
    await c.disconnect('rx');
    expect(c.testing, false);
    expect(c.latestTest, isNull);
    expect(c.error, contains('interrumpida'));
    c.dispose();
  });
  testWidgets('four tabs render and navigation works without hardware',
      (tester) async {
    final c = DatarayController(FakeRepository(), MemoryHistory());
    await tester.pumpWidget(
        ChangeNotifierProvider.value(value: c, child: const DatarayApp()));
    await tester.pumpAndSettle();
    expect(find.text('Módulos'), findsOneWidget);
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.text('Conecta un módulo desde Inicio.'), findsOneWidget);
    await tester.tap(find.text('Pruebas'));
    await tester.pumpAndSettle();
    expect(find.text('Prueba cómo viaja la luz'), findsOneWidget);
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.text('Aquí estarán tus pruebas'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });
}
