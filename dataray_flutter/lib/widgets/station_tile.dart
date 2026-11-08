import 'package:flutter/material.dart';
import '../models/station.dart';

/// Presentation only: the screen supplies the existing controller action.
class StationTile extends StatelessWidget {
  const StationTile(
      {required this.station,
      required this.connected,
      required this.onAction,
      super.key});
  final Station station;
  final bool connected;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final signal = station.rssi >= -60
        ? 'Fuerte'
        : station.rssi >= -80
            ? 'Normal'
            : 'Débil';
    final signalIcon = station.rssi >= -60
        ? Icons.signal_cellular_alt_rounded
        : station.rssi >= -80
            ? Icons.signal_cellular_alt_2_bar_rounded
            : Icons.signal_cellular_alt_1_bar_rounded;
    final action = connected ? 'Desconectar' : 'Conectar';
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(
                    station.role == StationRole.receiver
                        ? Icons.precision_manufacturing_outlined
                        : Icons.memory_outlined,
                    color: colors.onPrimaryContainer,
                    size: 22)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(station.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(station.roleLabel,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant)),
                ])),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 16, runSpacing: 8, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                  connected
                      ? Icons.check_circle_outline_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: connected ? colors.primary : colors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(connected ? 'Conectado' : 'Disponible',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: connected
                          ? colors.primary
                          : colors.onSurfaceVariant)),
            ]),
            Tooltip(
                message: 'Señal Bluetooth registrada en la última búsqueda.',
                child: Semantics(
                    label:
                        'Señal Bluetooth $signal, ${station.rssi} dBm, en la última búsqueda',
                    excludeSemantics: true,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(signalIcon,
                          size: 16, color: colors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Flexible(
                          child: Text('$signal · ${station.rssi} dBm',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: colors.onSurfaceVariant))),
                    ]))),
          ]),
          const SizedBox(height: 12),
          Align(
              alignment: Alignment.centerRight,
              child: Tooltip(
                  message: '$action ${station.name}',
                  child: connected
                      ? OutlinedButton.icon(
                          onPressed: onAction,
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          icon: const Icon(Icons.link_off_rounded, size: 18),
                          label: Text(action))
                      : FilledButton.tonalIcon(
                          onPressed: onAction,
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              backgroundColor: colors.primaryContainer,
                              foregroundColor: colors.onPrimaryContainer,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          icon: const Icon(Icons.bluetooth_connected_rounded,
                              size: 18),
                          label: Text(action)))),
        ]));
  }
}
