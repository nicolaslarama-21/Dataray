import 'package:flutter/material.dart';

void showSimpleHelp(BuildContext context, String title, String message) {
  showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
              icon: const Icon(Icons.lightbulb_outline_rounded),
              title: Text(title),
              content: SingleChildScrollView(child: Text(message)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Entendido'))
              ]));
}

class HelpButton extends StatelessWidget {
  const HelpButton({required this.title, required this.message, super.key});
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
      tooltip: 'Ayuda: $title',
      style: IconButton.styleFrom(
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.all(8),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.primary),
      onPressed: () => showSimpleHelp(context, title, message),
      icon: const Icon(Icons.question_mark_rounded, size: 18));
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {this.help, super.key});
  final String title;
  final String? help;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w700))),
        if (help != null) HelpButton(title: title, message: help!),
      ]);
}

void showQuickGuide(BuildContext context) {
  showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => FractionallySizedBox(
          heightFactor: .85,
          child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                Row(children: [
                  const Icon(Icons.auto_stories_outlined),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: Text('Una prueba, paso a paso',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold))),
                  IconButton(
                      tooltip: 'Cerrar guía',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close))
                ]),
                const SizedBox(height: 16),
                for (final step in const [
                  (
                    '1',
                    'Enciende tus módulos',
                    'Conecta por USB el módulo que envía luz y el que la recibe.'
                  ),
                  (
                    '2',
                    'Conéctalos al celular',
                    'En Inicio, toca Buscar ESP32 cercanos. Para hacer la prueba aquí, conecta un emisor y un receptor a este celular.'
                  ),
                  (
                    '3',
                    'Apunta la luz',
                    'Dirige el láser fijo hacia el sensor del receptor. Usa una superficie de prueba y evita apuntar a los ojos.'
                  ),
                  (
                    '4',
                    'Anota la distancia',
                    'Mide con una regla o cinta e ingresa los metros en Pruebas.'
                  ),
                  (
                    '5',
                    'Haz la prueba',
                    'Toca Enviar prueba y espera el resultado. Si no llega, revisa que los módulos estén conectados y la luz llegue al sensor.'
                  ),
                  (
                    '6',
                    'Guarda lo que pasó',
                    'Toca Guardar resultado. Después podrás verlo en Historial.'
                  ),
                ])
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(radius: 16, child: Text(step.$1)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(step.$2,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Text(step.$3)
                                    ]))
                              ]))),
                const SectionTitle('¿Quieres escribir con el brazo?'),
                const SizedBox(height: 8),
                const Text(
                    'Primero envía un mensaje desde Chat. Cuando llegue al receptor, toca Dibujar mensaje en Pruebas. Prepara el brazo sin láser antes de usarlo. Puedes detenerlo con el botón Detener brazo.'),
              ])));
}
