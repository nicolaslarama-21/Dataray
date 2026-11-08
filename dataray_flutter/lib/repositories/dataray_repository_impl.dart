import '../models/station.dart';
import '../models/node_event.dart';
import '../services/ble_service.dart';
import 'dataray_repository.dart';

class DatarayRepositoryImpl implements DatarayRepository {
  DatarayRepositoryImpl(this.ble);
  final BleService ble;
  @override
  Stream<NodeEvent> get events => ble.events;
  @override
  Future<List<Station>> scan() => ble.scanStations();
  @override
  Future<Station> connect(Station station) => ble.connect(station);
  @override
  Future<void> disconnect(String id) => ble.disconnect(id);
  @override
  Future<void> command(String id, Map<String, dynamic> command) =>
      ble.send(id, command);
  @override
  Future<void> dispose() => ble.dispose();
}
