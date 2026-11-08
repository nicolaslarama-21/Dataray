import '../features/canvas/controllers/canvas_controller.dart';
import '../features/canvas/data/canvas_store.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/wire_protocol.dart';
import '../models/chat_message.dart';
import '../models/node_event.dart';
import '../models/station.dart';
import '../models/test_result.dart';
import '../repositories/dataray_repository.dart';
import '../repositories/history_store.dart';

class DatarayController extends ChangeNotifier {
  DatarayController(this.repository, this.historyStore,
      {CanvasStore? canvasStore})
      : canvases = CanvasController(canvasStore ?? MobileCanvasStore()) {
    canvases.addListener(_notify);
    _subscription = repository.events.listen(_onEvent);
    _heartbeat = Timer.periodic(const Duration(seconds: 2), (_) {
      final rx = receiver;
      if (rx != null && statuses[rx.id]?['robotBusy'] == true) {
        unawaited(
            repository.command(rx.id, {'cmd': 'ping'}).catchError((Object e) {
          error = 'Sin comunicación con el brazo: $e';
          _notify();
        }));
      }
    });
    unawaited(_loadHistory());
  }
  final CanvasController canvases;
  final DatarayRepository repository;
  final HistoryStore historyStore;
  late final StreamSubscription<NodeEvent> _subscription;
  late final Timer _heartbeat;
  bool _disposed = false;
  bool scanning = false;
  bool working = false;
  bool testing = false;
  bool saving = false;
  String? error;
  String? notice;
  final nodes = <String, Station>{};
  final statuses = <String, Map<String, dynamic>>{};
  List<Station> stations = [];
  final messages = <ChatMessage>[];
  List<TestResult> history = [];
  TestResult? latestTest;
  double distance = 1;
  int _sequence = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
  int? _pendingTest;
  double _testDistance = 1;
  Timer? _testTimer;
  final _messageTimers = <int, Timer>{};
  Station? get transmitter =>
      nodes.values.where((s) => s.role == StationRole.transmitter).firstOrNull;
  Station? get receiver =>
      nodes.values.where((s) => s.role == StationRole.receiver).firstOrNull;
  bool get canSend =>
      transmitter != null &&
      !working &&
      statuses[transmitter!.id]?['txBusy'] != true &&
      !messages.any((m) => m.state == MessageState.queued) &&
      !testing;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _loadHistory() async {
    try {
      history = await historyStore.load();
    } catch (e) {
      error = 'No se pudo leer el historial: $e';
    }
    _notify();
  }

  void clearError() {
    error = null;
    _notify();
  }

  Future<void> setThreshold(int value) => _operation(() async {
        if (value < 100 || value > 3995) {
          throw const FormatException('El umbral debe estar entre 100 y 3995.');
        }
        if (receiver != null) {
          await repository
              .command(receiver!.id, {'cmd': 'threshold', 'value': value});
        }
      });
  Future<void> drawLastMessage() => _operation(() async {
        if (receiver != null) {
          await repository.command(receiver!.id, {'cmd': 'draw'});
        }
      });
  Future<void> stopRobot() async {
    final rx = receiver;
    if (rx == null) return;
    try {
      await repository.command(rx.id, {'cmd': 'stop'});
    } catch (e) {
      error = e.toString();
    }
    _notify();
  }

  Future<void> _operation(Future<void> Function() action) async {
    if (working) return;
    working = true;
    error = null;
    notice = null;
    _notify();
    try {
      await action();
    } catch (e) {
      error = e.toString();
    } finally {
      working = false;
      _notify();
    }
  }

  Future<void> scan() async {
    if (scanning || working) return;
    scanning = true;
    error = null;
    _notify();
    try {
      stations = await repository.scan();
    } catch (e) {
      error = e.toString();
    } finally {
      scanning = false;
      _notify();
    }
  }

  Future<void> connect(Station station) => _operation(() async {
        if (nodes.containsKey(station.id)) return;
        final node = await repository.connect(station);
        if (nodes.values.any((n) => n.role == node.role)) {
          await repository.disconnect(node.id);
          throw StateError(
              'Ya hay un módulo de este tipo conectado. Desconéctalo primero.');
        }
        nodes[node.id] = node;
      });
  Future<void> disconnect(String id) =>
      _operation(() => repository.disconnect(id));

  Future<bool> send(String raw) async {
    if (!canSend) return false;
    var success = false;
    await _operation(() async {
      final text = normalizeMessage(raw);
      final node = transmitter!;
      final id = ++_sequence;
      final message = ChatMessage(
          id: id,
          text: text,
          mine: true,
          time: DateTime.now(),
          stationId: node.id,
          state: MessageState.queued);
      messages.add(message);
      _notify();
      _messageTimers[id] = Timer(const Duration(seconds: 20), () {
        if (message.state == MessageState.queued) {
          message.state = MessageState.failed;
          error = 'No se confirmó la emisión. Revisa la conexión.';
          _notify();
        }
        _messageTimers.remove(id);
      });
      try {
        await repository
            .command(node.id, {'cmd': 'send', 'id': id, 'text': text});
        success = true;
      } catch (_) {
        message.state = MessageState.failed;
        _messageTimers.remove(id)?.cancel();
        rethrow;
      }
    });
    return success;
  }

  Future<void> startTest() async {
    if (!canSend || receiver == null) return;
    await _operation(() async {
      if (!distance.isFinite || distance <= 0) {
        throw const FormatException('Indica una distancia positiva en metros.');
      }
      testing = true;
      latestTest = null;
      _pendingTest = ++_sequence;
      _testDistance = distance;
      _testTimer = Timer(const Duration(seconds: 20), () {
        testing = false;
        _pendingTest = null;
        error =
            'Sin resultado del receptor: revisa alineación y conexión. No se calculó BER.';
        _notify();
      });
      try {
        await repository
            .command(transmitter!.id, {'cmd': 'test', 'id': _pendingTest});
      } catch (_) {
        _endTest();
        rethrow;
      }
    });
  }

  void _endTest() {
    testing = false;
    _pendingTest = null;
    _testTimer?.cancel();
  }

  Future<void> saveTest() async {
    final result = latestTest;
    if (result == null ||
        saving ||
        history
            .any((r) => r.id == result.id && r.stationId == result.stationId)) {
      return;
    }
    saving = true;
    error = null;
    _notify();
    final updated = [result, ...history].take(200).toList();
    try {
      await historyStore.save(updated);
      history = updated;
      notice = 'Resultado guardado en este teléfono.';
    } catch (e) {
      error = 'No se pudo guardar: $e';
    } finally {
      saving = false;
      _notify();
    }
  }

  void _onEvent(NodeEvent event) {
    canvases.handle(event,
        receiver: nodes[event.stationId]?.role == StationRole.receiver);
    final data = event.data;
    if (event.kind == NodeEventKind.disconnected) {
      nodes.remove(event.stationId);
      statuses.remove(event.stationId);
      for (final m in messages.where((m) =>
          m.stationId == event.stationId && m.state == MessageState.queued)) {
        m.state = MessageState.failed;
        _messageTimers.remove(m.id)?.cancel();
      }
      if (testing) {
        _endTest();
        error = 'Prueba interrumpida por desconexión.';
      }
    } else if (event.kind == NodeEventKind.error || data['type'] == 'error') {
      error = '${data['message'] ?? 'Error del ESP32'}';
      final id = data['id'];
      for (final m in messages.where((m) => m.mine && m.id == id)) {
        m.state = MessageState.failed;
        _messageTimers.remove(m.id)?.cancel();
      }
      if (id == _pendingTest) _endTest();
    } else if (event.kind == NodeEventKind.data) {
      switch (data['type']) {
        case 'status':
          statuses[event.stationId] = data;
        case 'message':
          if (data['text'] is String && data['id'] is int) {
            messages.add(ChatMessage(
                id: data['id'] as int,
                text: data['text'] as String,
                mine: false,
                time: DateTime.now(),
                stationId: event.stationId,
                state: MessageState.received));
          }
        case 'tx':
          for (final m in messages.where((m) =>
              m.mine && m.id == data['id'] && m.stationId == event.stationId)) {
            m.state = MessageState.transmitted;
            _messageTimers.remove(m.id)?.cancel();
          }
        case 'test':
          final id = data['id'];
          final bits = data['bits'];
          final errors = data['errors'];
          if (id is int &&
              bits is int &&
              errors is int &&
              bits > 0 &&
              errors >= 0 &&
              errors <= bits &&
              data['crcOk'] is bool &&
              nodes[event.stationId]?.role == StationRole.receiver &&
              (!testing || id == _pendingTest)) {
            latestTest = TestResult(
                id: id,
                time: DateTime.now(),
                distance: testing ? _testDistance : distance,
                bits: bits,
                errors: errors,
                crcOk: data['crcOk'] as bool,
                stationId: event.stationId);
            _endTest();
          }
      }
    }
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _heartbeat.cancel();
    canvases.removeListener(_notify);
    canvases.dispose();
    _testTimer?.cancel();
    for (final timer in _messageTimers.values) {
      timer.cancel();
    }
    unawaited(_subscription.cancel());
    unawaited(repository.dispose());
    super.dispose();
  }
}
