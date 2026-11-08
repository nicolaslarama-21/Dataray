import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/dataray_controller.dart';
import '../widgets/common.dart';
import '../widgets/station_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.onTest, super.key});
  final VoidCallback onTest;
  @override
  Widget build(BuildContext context) {
    final c = context.watch<DatarayController>();
    final colors = Theme.of(context).colorScheme;
    final available =
        c.stations.where((s) => !c.nodes.containsKey(s.id)).toList();
    final enabled = !c.working && !c.scanning;
    return Column(children: [
      Expanded(
          child: ListView(
              key: const ValueKey('home-modules-scroll'),
              padding: const EdgeInsets.all(16),
              children: [
            Container(
                decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.outlineVariant)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('Módulos',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                Text(
                                    'Busca un ESP32 para enviar o recibir mensajes.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            color: colors.onSurfaceVariant)),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                    onPressed: enabled ? c.scan : null,
                                    style: FilledButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                    icon: c.scanning
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: colors.primary))
                                        : const Icon(
                                            Icons.bluetooth_searching_rounded,
                                            size: 20),
                                    label: Text(c.scanning
                                        ? 'Buscando ESP32…'
                                        : 'Buscar ESP32 cercanos')),
                              ])),
                      if (c.scanning)
                        const LinearProgressIndicator(minHeight: 2),
                      if (c.nodes.isNotEmpty) ...[
                        _GroupLabel('Conectados', c.nodes.length),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(children: [
                              for (final (i, station)
                                  in c.nodes.values.indexed) ...[
                                if (i > 0) const Divider(height: 1),
                                StationTile(
                                    station: station,
                                    connected: true,
                                    onAction: enabled
                                        ? () => c.disconnect(station.id)
                                        : null),
                              ],
                            ])),
                      ],
                      if (available.isNotEmpty) ...[
                        _GroupLabel('Disponibles', available.length),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(children: [
                              for (final (i, station) in available.indexed) ...[
                                if (i > 0) const Divider(height: 1),
                                StationTile(
                                    station: station,
                                    connected: false,
                                    onAction: enabled
                                        ? () => c.connect(station)
                                        : null),
                              ],
                            ])),
                      ],
                      if (c.stations.isEmpty && c.nodes.isEmpty && !c.scanning)
                        const EmptyState(
                            icon: Icons.bluetooth_rounded,
                            title: 'Aquí aparecerán tus módulos',
                            description:
                                'Enciende tu ESP32 y toca Buscar ESP32 cercanos.'),
                      if (c.scanning && available.isEmpty && c.nodes.isEmpty)
                        Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            child: Semantics(
                                liveRegion: true,
                                child:
                                    const Text('Buscando módulos cercanos…'))),
                    ])),
          ])),
      Container(
          decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.outlineVariant))),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SafeArea(
              top: false,
              child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                      key: const ValueKey('home-test-button'),
                      onPressed: onTest,
                      style: FilledButton.styleFrom(
                          backgroundColor: colors.primaryContainer,
                          foregroundColor: colors.onPrimaryContainer,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('Ir a pruebas del enlace'))))),
    ]);
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label, this.count);
  final String label;
  final int count;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
        color: colors.surfaceContainerLow,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Expanded(
              child:
                  Text(label, style: Theme.of(context).textTheme.labelLarge)),
          Text('$count', style: Theme.of(context).textTheme.labelLarge)
        ]));
  }
}
