enum StationRole { transmitter, receiver, unknown }

class Station {
  const Station(
      {required this.id,
      required this.name,
      required this.rssi,
      this.role = StationRole.unknown});
  final String id;
  final String name;
  final int rssi;
  final StationRole role;
  Station withRole(StationRole value) =>
      Station(id: id, name: name, rssi: rssi, role: value);
  String get roleLabel => switch (role) {
        StationRole.transmitter => 'Envía mensajes con luz',
        StationRole.receiver => 'Recibe mensajes y mueve el brazo',
        StationRole.unknown => 'Conecta para ver su función',
      };
}
