enum MessageState { queued, transmitted, failed, received }

class ChatMessage {
  ChatMessage(
      {required this.id,
      required this.text,
      required this.mine,
      required this.time,
      required this.stationId,
      required this.state});
  final int id;
  final String text;
  final bool mine;
  final DateTime time;
  final String stationId;
  MessageState state;
  String get stateLabel => switch (state) {
        MessageState.queued => 'Esperando para enviar',
        MessageState.transmitted => 'Luz enviada · recepción sin confirmar',
        MessageState.failed => 'No se pudo enviar',
        MessageState.received => 'Mensaje recibido',
      };
}
