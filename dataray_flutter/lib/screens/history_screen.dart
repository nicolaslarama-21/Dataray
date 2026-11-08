import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/dataray_controller.dart';
import '../models/test_result.dart';
import '../widgets/common.dart';
import '../widgets/help.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = context.watch<DatarayController>().history;
    if (history.isEmpty) {
      return const Center(
          child: EmptyState(
              icon: Icons.history_rounded,
              title: 'Aquí estarán tus pruebas',
              description:
                  'Guarda un resultado desde Pruebas para consultarlo y compararlo después.'));
    }
    // Date grouping is presentation only; retain the repository's result order.
    final groups = <List<TestResult>>[];
    for (final result in history) {
      if (groups.isEmpty ||
          !DateUtils.isSameDay(groups.last.last.time, result.time)) {
        groups.add([]);
      }
      groups.last.add(result);
    }
    return ListView.builder(
        key: const ValueKey('history-results-list'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: groups.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pruebas guardadas',
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                          '${history.length} ${history.length == 1 ? 'resultado guardado' : 'resultados guardados'} en este teléfono',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                    ]));
          }
          final results = groups[index - 1];
          return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(dateText(results.first.time),
                            style: theme.textTheme.labelLarge)),
                    Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: Column(children: [
                          for (final (i, result) in results.indexed) ...[
                            if (i > 0) const Divider(indent: 16, endIndent: 16),
                            _ResultRow(result: result),
                          ],
                        ])),
                  ]));
        });
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result});
  final TestResult result;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
        onTap: () => _showResult(context, result),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.schedule_rounded,
                    size: 16, color: colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(clockText(result.time),
                        style: Theme.of(context).textTheme.titleSmall)),
                Flexible(child: _ResultStatus(result.crcOk)),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: colors.onSurfaceVariant),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 24, runSpacing: 8, children: [
                _ResultValue('Distancia', '${result.distance} m'),
                _ResultValue('Errores (BER)', _ber(result)),
              ]),
            ])));
  }
}

class _ResultStatus extends StatelessWidget {
  const _ResultStatus(this.ok);
  final bool ok;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground =
        ok ? colors.onSecondaryContainer : colors.onErrorContainer;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: ok ? colors.secondaryContainer : colors.errorContainer,
            borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(ok ? Icons.check_rounded : Icons.error_outline_rounded,
              size: 14, color: foreground),
          const SizedBox(width: 4),
          Flexible(
              child: Text(ok ? 'Sin cambios' : 'Con cambios',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: foreground))),
        ]));
  }
}

class _ResultValue extends StatelessWidget {
  const _ResultValue(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ]);
}

String _ber(TestResult result) => result.ber == null
    ? 'Sin medir'
    : result.ber == 0
        ? '0 %'
        : '${(result.ber! * 100).toStringAsPrecision(3)} %';
void _showResult(BuildContext context, TestResult result) {
  showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
          top: false,
          child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * .85),
              child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text('Resultado de la prueba',
                                  style:
                                      Theme.of(context).textTheme.titleLarge)),
                          IconButton(
                              tooltip: 'Cerrar resultado',
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close_rounded))
                        ]),
                        const SizedBox(height: 8),
                        Text(
                            '${dateText(result.time)} · ${clockText(result.time)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                        const SizedBox(height: 20),
                        _ResultStatus(result.crcOk),
                        const SizedBox(height: 16),
                        Text(result.crcOk
                            ? 'El receptor revisó este mensaje sin encontrar cambios.'
                            : 'El receptor encontró cambios en el mensaje recibido.'),
                        const SizedBox(height: 24),
                        _ResultValue(
                            'Distancia entre módulos', '${result.distance} m'),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        SectionTitle('Errores (BER)',
                            help:
                                'La prueba compara pequeñas partes del mensaje que llegaron al receptor. Aquí revisó ${result.bits} partes y encontró ${result.errors} cambios.\n\n0 % significa que no vio cambios en esas partes. Los mensajes que no llegaron no se incluyen.'),
                        const SizedBox(height: 8),
                        Text(_ber(result),
                            style: Theme.of(context).textTheme.headlineSmall),
                      ])))));
}
