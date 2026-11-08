import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/ble_constants.dart';
import '../core/wire_protocol.dart';
import '../models/node_event.dart';
import '../models/station.dart';

class _Session {
  _Session(this.device, this.rx);
  final BluetoothDevice device;
  final BluetoothCharacteristic rx;
  final subscriptions = <StreamSubscription<dynamic>>[];
  Future<void> writes = Future.value();
}

class BleService {
  final _events = StreamController<NodeEvent>.broadcast();
  final _sessions = <String, _Session>{};
  Stream<NodeEvent> get events => _events.stream;

  Future<List<Station>> scanStations() async {
    if (kIsWeb ||
        ![TargetPlatform.android, TargetPlatform.iOS]
            .contains(defaultTargetPlatform)) {
      throw StateError(
          'BLE está preparado para Android e iOS en un teléfono real.');
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final permissions = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse
      ].request();
      if (permissions.values.any((p) => p.isPermanentlyDenied)) {
        throw StateError(
            'Habilita los permisos Bluetooth/ubicación en Ajustes.');
      }
    }
    if (!await FlutterBluePlus.isSupported) {
      throw StateError('Este teléfono no admite BLE.');
    }
    await FlutterBluePlus.adapterState
        .where((s) => s != BluetoothAdapterState.unknown)
        .first
        .timeout(const Duration(seconds: 8));
    if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      throw StateError('Activa Bluetooth y concede los permisos para buscar.');
    }
    final found = <String, Station>{};
    Object? scanError;
    final sub = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        final name = result.advertisementData.advName;
        if (name.startsWith(BleConstants.stationPrefix)) {
          found[result.device.remoteId.str] = Station(
              id: result.device.remoteId.str, name: name, rssi: result.rssi);
        }
      }
    }, onError: (Object e) {
      scanError = e;
    });
    try {
      await FlutterBluePlus.startScan(
          withServices: [BleConstants.serviceUuid],
          timeout: const Duration(seconds: 6));
      await FlutterBluePlus.isScanning
          .where((value) => !value)
          .first
          .timeout(const Duration(seconds: 10));
      if (scanError != null) throw StateError('$scanError');
      return found.values.toList()..sort((a, b) => b.rssi.compareTo(a.rssi));
    } finally {
      await FlutterBluePlus.stopScan();
      await sub.cancel();
    }
  }

  Future<Station> connect(Station station) async {
    final device = BluetoothDevice.fromId(station.id);
    try {
      await device.connect(
          license: License.nonprofit,
          timeout: const Duration(seconds: 15),
          mtu: null);
      final services = await device.discoverServices();
      final service =
          services.firstWhere((s) => s.uuid == BleConstants.serviceUuid);
      BluetoothCharacteristic characteristic(Guid uuid) =>
          service.characteristics.firstWhere((c) => c.uuid == uuid);
      final info = jsonDecode(
              utf8.decode(await characteristic(BleConstants.infoUuid).read()))
          as Map<String, dynamic>;
      if (info['protocol'] != 1 || !['tx', 'rx'].contains(info['role'])) {
        throw StateError('Perfil o versión de firmware incompatible.');
      }
      final result = station.withRole(info['role'] == 'tx'
          ? StationRole.transmitter
          : StationRole.receiver);
      final session = _Session(device, characteristic(BleConstants.rxUuid));
      _sessions[station.id] = session;
      final decoder = LineDecoder();
      final tx = characteristic(BleConstants.txUuid);
      session.subscriptions.add(tx.onValueReceived.listen((bytes) {
        try {
          for (final event in decoder.add(bytes)) {
            _events.add(NodeEvent(station.id, NodeEventKind.data, event));
          }
        } catch (e) {
          _events.add(NodeEvent(station.id, NodeEventKind.error,
              {'message': 'Respuesta BLE inválida: $e'}));
        }
      }));
      await tx.setNotifyValue(true);
      session.subscriptions.add(device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          unawaited(_release(station.id));
        }
      }));
      if (!device.isConnected) {
        throw StateError('El dispositivo se desconectó.');
      }
      _events.add(NodeEvent(station.id, NodeEventKind.connected));
      return result;
    } catch (_) {
      await disconnect(station.id);
      await device.disconnect();
      rethrow;
    }
  }

  Future<void> send(String id, Map<String, dynamic> command) async {
    final session = _sessions[id];
    if (session == null) throw StateError('Estación desconectada.');
    final data = utf8.encode('${jsonEncode(command)}\n');
    // MTU 23 permits 20 payload bytes. Serialize fragmented commands.
    final write = session.writes.then((_) async {
      for (var i = 0; i < data.length; i += 20) {
        await session.rx.write(data.sublist(i, (i + 20).clamp(0, data.length)),
            withoutResponse: false);
      }
    });
    session.writes = write.catchError((Object _) {});
    await write;
  }

  Future<void> _release(String id) async {
    final session = _sessions.remove(id);
    if (session == null) return;
    for (final sub in session.subscriptions) {
      await sub.cancel();
    }
    _events.add(NodeEvent(id, NodeEventKind.disconnected));
  }

  Future<void> disconnect(String id) async {
    final device = _sessions[id]?.device;
    await _release(id);
    if (device != null) await device.disconnect();
  }

  Future<void> dispose() async {
    for (final id in _sessions.keys.toList()) {
      await disconnect(id);
    }
    await _events.close();
  }
}
