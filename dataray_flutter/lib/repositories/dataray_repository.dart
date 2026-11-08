import '../models/station.dart';
import '../models/node_event.dart';

abstract class DatarayRepository {
  Stream<NodeEvent> get events;
  Future<List<Station>> scan();
  Future<Station> connect(Station station);
  Future<void> disconnect(String id);
  Future<void> command(String id, Map<String, dynamic> command);
  Future<void> dispose();
}
