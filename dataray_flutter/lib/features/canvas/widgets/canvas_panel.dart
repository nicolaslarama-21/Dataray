import 'package:flutter/material.dart';
import '../../../widgets/common.dart';
import '../../../widgets/help.dart';
import '../controllers/canvas_controller.dart';
import '../models/laser_canvas.dart';
import 'laser_canvas_view.dart';

class CanvasPanel extends StatelessWidget {
  const CanvasPanel(
      {required this.controller,
      required this.compact,
      required this.height,
      this.onDraw,
      this.onStop,
      super.key});
  final CanvasController controller;
  final bool compact;
  final double height;
  final VoidCallback? onDraw, onStop;
  void _open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => CanvasViewer(controller: controller)));
  @override
  Widget build(BuildContext context) {
    final document = controller.current;
    if (compact) {
      return Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Row(children: [
            const Icon(Icons.gesture_rounded, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text(document?.stateLabel ?? 'Lienzo listo',
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
            TextButton(
                onPressed: () => _open(context),
                child: const Text('Ver lienzo')),
            IconButton(
                tooltip: 'Lienzos guardados',
                onPressed: () => showSavedCanvases(context, controller),
                icon: const Icon(Icons.collections_outlined)),
          ]));
    }
    return Card(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Lienzo del láser',
                              style: Theme.of(context).textTheme.titleSmall),
                          Text(document?.sourceLabel ?? 'Esperando un mensaje',
                              style: Theme.of(context).textTheme.bodySmall),
                        ])),
                    IconButton(
                        tooltip: 'Qué muestra el lienzo',
                        onPressed: () => showSimpleHelp(
                            context,
                            'Del mensaje al lienzo',
                            'El texto que recibe el fotodiodo aparece debajo del dibujo.\n\nVista previa: es una guía hecha por la app, antes de mover el brazo.\n\nTrayectoria del brazo: son los puntos que el ESP32 ordenó dibujar; no es una foto ni una medición del movimiento real.\n\nSeguimiento externo: permite recibir puntos de un sistema de captura. Conectar un control Wii todavía requiere un programa puente y calibración; no está implementado aquí.'),
                        icon: const Icon(Icons.help_outline_rounded, size: 20)),
                    IconButton(
                        tooltip: 'Ampliar lienzo',
                        onPressed: () => _open(context),
                        icon: const Icon(Icons.open_in_full_rounded, size: 20)),
                  ]),
                  const SizedBox(height: 8),
                  SizedBox(
                      height: height,
                      child: LaserCanvasView(document: document)),
                  const SizedBox(height: 8),
                  Text(
                      document == null
                          ? 'El fotodiodo aún no recibió un mensaje.'
                          : 'Mensaje de este lienzo: ${document.text}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
                  if (document != null)
                    Text(document.stateLabel,
                        style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (controller.recording)
                          FilledButton.tonalIcon(
                              onPressed: onStop,
                              icon: const Icon(Icons.stop_rounded, size: 18),
                              label: const Text('Detener'))
                        else
                          FilledButton.tonalIcon(
                              onPressed: onDraw,
                              icon: const Icon(Icons.draw_outlined, size: 18),
                              label: const Text('Dibujar')),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                              tooltip: document?.source == CanvasSource.preview
                                  ? 'Guardar vista previa'
                                  : 'Guardar lienzo',
                              onPressed: controller.canSave
                                  ? controller.saveCurrent
                                  : null,
                              icon: const Icon(Icons.save_outlined)),
                          IconButton(
                              tooltip: 'Lienzos guardados',
                              onPressed: () =>
                                  showSavedCanvases(context, controller),
                              icon: const Icon(Icons.collections_outlined)),
                        ]),
                      ]),
                  if (controller.error != null)
                    Text(controller.error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  if (controller.notice != null)
                    Text(controller.notice!,
                        style: Theme.of(context).textTheme.bodySmall),
                ])));
  }
}

class CanvasViewer extends StatelessWidget {
  const CanvasViewer({this.controller, this.document, super.key});
  final CanvasController? controller;
  final LaserCanvas? document;
  @override
  Widget build(BuildContext context) => controller == null
      ? _build(context, document)
      : ListenableBuilder(
          listenable: controller!,
          builder: (context, _) => _build(context, controller!.current));
  Widget _build(BuildContext context, LaserCanvas? canvas) => Scaffold(
      appBar: AppBar(title: const Text('Lienzo'), actions: [
        if (controller != null)
          IconButton(
              tooltip: 'Guardar lienzo',
              onPressed: controller!.canSave ? controller!.saveCurrent : null,
              icon: const Icon(Icons.save_outlined)),
      ]),
      body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(canvas?.sourceLabel ?? 'Sin trazado',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(canvas?.stateLabel ??
                        'Espera un mensaje recibido por el fotodiodo.'),
                    const SizedBox(height: 16),
                    Expanded(
                        child: ClipRect(
                            child: InteractiveViewer(
                                minScale: 1,
                                maxScale: 5,
                                child: Center(
                                    child: AspectRatio(
                                        aspectRatio: 1.5,
                                        child: LaserCanvasView(
                                            document: canvas)))))),
                    const SizedBox(height: 16),
                    Text('Mensaje de este lienzo',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Text(canvas?.text ?? 'Sin mensaje recibido'),
                    if (controller?.notice != null) Text(controller!.notice!),
                    if (controller?.error != null)
                      Text(controller!.error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                  ]))));
}

void showSavedCanvases(BuildContext context, CanvasController controller) {
  showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => FractionallySizedBox(
          heightFactor: .8,
          child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => Column(children: [
                    Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
                        child: Row(children: [
                          const Expanded(
                              child: Text('Lienzos guardados',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600))),
                          IconButton(
                              tooltip: 'Cerrar lienzos guardados',
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close_rounded)),
                        ])),
                    Expanded(
                        child: controller.saved.isEmpty
                            ? const Center(
                                child: EmptyState(
                                    icon: Icons.collections_outlined,
                                    title: 'Guarda tu primer lienzo',
                                    description:
                                        'Usa el botón de guardar después de recibir un trazado. También puedes guardar una vista previa.'))
                            : ListView.separated(
                                itemCount: controller.saved.length,
                                padding: const EdgeInsets.all(16),
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (context, index) {
                                  final canvas = controller.saved[index];
                                  return ListTile(
                                      title: Text(
                                          canvas.text.isEmpty
                                              ? 'Sin texto asociado'
                                              : canvas.text,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      subtitle: Text(
                                          '${canvas.sourceLabel} · ${dateText(canvas.time)} ${clockText(canvas.time)}\n${canvas.stateLabel}'),
                                      trailing: const Icon(
                                          Icons.chevron_right_rounded),
                                      onTap: () {
                                        final navigator = Navigator.of(context,
                                            rootNavigator: true);
                                        Navigator.pop(sheetContext);
                                        navigator.push(MaterialPageRoute<void>(
                                            builder: (_) => CanvasViewer(
                                                document: canvas)));
                                      });
                                })),
                  ]))));
}
