import '../features/canvas/widgets/canvas_panel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/dataray_controller.dart';
import '../widgets/common.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();
  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> _send(DatarayController c) async {
    final sent = await c.send(input.text);
    if (!mounted) return;
    if (sent) input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<DatarayController>();
    final latestReceived = c.messages
        .where((m) => !m.mine && m.stationId == c.receiver?.id)
        .lastOrNull;
    final document = c.canvases.current;
    final canDraw = c.receiver != null &&
        !c.working &&
        !c.canvases.recording &&
        c.statuses[c.receiver!.id]?['robotBusy'] != true &&
        latestReceived != null &&
        document?.messageId == latestReceived.id &&
        document?.stationId == c.receiver!.id;
    return LayoutBuilder(
        builder: (context, constraints) => Column(children: [
              CanvasPanel(
                  controller: c.canvases,
                  compact: constraints.maxHeight < 500,
                  height: (constraints.maxHeight * .22).clamp(100, 150),
                  onDraw: canDraw ? c.drawLastMessage : null,
                  onStop: c.receiver != null ? c.stopRobot : null),
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(c.transmitter != null
                      ? 'Listo para enviar mensajes'
                      : c.receiver != null
                          ? 'Escuchando los mensajes que llegan'
                          : 'Conecta un módulo desde Inicio.')),
              Expanded(
                  child: c.messages.isEmpty
                      ? const Center(
                          child: EmptyState(
                              icon: Icons.forum_outlined,
                              title: 'Tus palabras viajan con luz',
                              description:
                                  'Envía una palabra o espera a que llegue un mensaje.'))
                      : ListView.builder(
                          controller: scroll,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: c.messages.length,
                          itemBuilder: (_, i) {
                            final m = c.messages[c.messages.length - 1 - i];
                            return Align(
                                alignment: m.mine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                    constraints:
                                        const BoxConstraints(maxWidth: 310),
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                        color: m.mine
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primaryContainer
                                            : Theme.of(context)
                                                .colorScheme
                                                .surface,
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              m.mine
                                                  ? 'Tú · ${clockText(m.time)}'
                                                  : 'Receptor · ${clockText(m.time)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall),
                                          const SizedBox(height: 6),
                                          Text(m.text,
                                              style: const TextStyle(
                                                  fontSize: 16)),
                                          const SizedBox(height: 8),
                                          Text(m.stateLabel,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall),
                                        ])));
                          })),
              SafeArea(
                  top: false,
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: TextField(
                                    controller: input,
                                    enabled: c.transmitter != null,
                                    maxLength: 64,
                                    minLines: 1,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                        hintText: 'Escribe un mensaje',
                                        helperText:
                                            'Se envía en mayúsculas y sin tildes'),
                                    onSubmitted: (_) =>
                                        c.canSend ? _send(c) : null)),
                            const SizedBox(width: 8),
                            IconButton.filled(
                                tooltip: 'Enviar por láser',
                                onPressed: c.canSend ? () => _send(c) : null,
                                icon: const Icon(Icons.send)),
                          ]))),
            ]));
  }
}
