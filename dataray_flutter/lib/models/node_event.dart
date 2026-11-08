enum NodeEventKind { connected, disconnected, data, error }

class NodeEvent {
  const NodeEvent(this.stationId, this.kind, [this.data = const {}]);
  final String stationId;
  final NodeEventKind kind;
  final Map<String, dynamic> data;
}
