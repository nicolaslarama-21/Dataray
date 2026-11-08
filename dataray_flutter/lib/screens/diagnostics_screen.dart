import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/dataray_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/help.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});
  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  final distance = TextEditingController(text: '1.0');
  final threshold = TextEditingController(text: '1800');
  @override
  void dispose() {
    distance.dispose();
    threshold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<DatarayController>();
    final rx = c.receiver;
    final status = rx == null ? <String, dynamic>{} : c.statuses[rx.id] ?? {};
    final result = c.latestTest;
    final parsed = double.tryParse(distance.text.replaceAll(',', '.'));
    final validDistance = parsed != null && parsed.isFinite && parsed > 0;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Prueba cómo viaja la luz',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text(
          'Conecta el emisor y el receptor a este celular para empezar.'),
      const SizedBox(height: 20),
      LayoutBuilder(builder: (context, box) {
        final width =
            box.maxWidth < 340 ? box.maxWidth : (box.maxWidth - 12) / 2;
        return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metric(
                  Icons.analytics_outlined,
                  'Errores (BER)',
                  result == null
                      ? 'Sin medir'
                      : '${(result.ber! * 100).toStringAsPrecision(3)} %',
                  '¿Llegó bien el mensaje?',
                  'La prueba envía un mensaje conocido. Comparamos lo que salió con lo que llegó.\n\n0 % significa que no encontramos cambios en la parte que pudimos comparar. Un número mayor significa que llegaron cambios.\n\nSi un mensaje no llega, no podemos medirlo: la app te avisará. Esta medida no cuenta los mensajes perdidos.',
                  AppTheme.blue(context)),
              _Metric(
                  Icons.straighten_rounded,
                  'Distancia',
                  '${c.distance.toStringAsFixed(1)} m',
                  '¿Qué distancia es?',
                  'Es la separación entre los dos módulos. Mídela con una regla o cinta y escríbela abajo. La app no la mide sola.',
                  AppTheme.lavender(context)),
              _Metric(
                  Icons.wb_sunny_outlined,
                  'Luz recibida',
                  '${status['adc'] ?? '—'}',
                  '¿Cuánta luz llega?',
                  'Este número muestra la luz que detecta el sensor. Va de 0 a 4095. Con el circuito recomendado, más luz da un número mayor.\n\nNo son metros ni la señal Bluetooth. Si el número casi no cambia al iluminar el sensor, revisa su conexión.',
                  AppTheme.mint(context)),
              _Metric(
                  Icons.mark_chat_read_outlined,
                  'Mensajes correctos',
                  '${status['packets'] ?? '—'}',
                  '¿Qué mensajes se cuentan?',
                  'Cuenta los mensajes que el receptor pudo revisar sin encontrar cambios. Esa revisión se llama CRC.\n\nEl contador vuelve a cero al reiniciar el receptor. No significa que todos los mensajes enviados hayan llegado.',
                  AppTheme.blue(context)),
            ].map((metric) => SizedBox(width: width, child: metric)).toList());
      }),
      const SizedBox(height: 20),
      TextField(
          controller: distance,
          enabled: !c.testing,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: 'Distancia en metros',
              prefixIcon: Icon(Icons.straighten_rounded)),
          onChanged: (value) {
            final number = double.tryParse(value.replaceAll(',', '.'));
            if (number != null && number.isFinite && number > 0) {
              c.distance = number;
            }
            setState(() {});
          }),
      const SizedBox(height: 14),
      StatusPill(
          c.testing
              ? 'Esperando el resultado…'
              : result != null
                  ? result.crcOk
                      ? 'El mensaje llegó sin cambios'
                      : 'El mensaje llegó con cambios'
                  : rx != null && c.transmitter != null
                      ? 'Todo listo para probar'
                      : 'Falta conectar los dos módulos',
          active: !c.testing && rx != null && c.transmitter != null),
      const SizedBox(height: 14),
      FilledButton.icon(
          onPressed: c.canSend && rx != null && !c.testing && validDistance
              ? c.startTest
              : null,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(c.testing ? 'Probando…' : 'Enviar prueba')),
      const SizedBox(height: 8),
      OutlinedButton.icon(
          onPressed: result != null && !c.saving ? c.saveTest : null,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar resultado')),
      if (c.notice != null)
        Padding(padding: const EdgeInsets.all(8), child: Text(c.notice!)),
      const SizedBox(height: 24),
      Card(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle('Ajustar el sensor',
                        help:
                            'El sensor necesita distinguir cuándo hay luz y cuándo no.\n\n1. Mira el número de Luz recibida sin iluminar el sensor.\n2. Ilumínalo con una luz de prueba y mira el nuevo número.\n3. Elige un valor entre ambos y escríbelo aquí. Deja un margen: los números deberían estar separados por más de 160.\n\nPor ejemplo: si ves 500 sin luz y 2500 con luz, prueba con 1500. Si el número siempre queda cerca de 0 o 4095, revisa el circuito con quien lo armó. El ajuste se pierde al apagar el módulo.'),
                    const SizedBox(height: 8),
                    Text('Valor actual: ${status['threshold'] ?? '—'}'),
                    Text(status['light'] == null
                        ? 'Esperando al sensor'
                        : status['light'] == true
                            ? 'El sensor ve luz'
                            : 'El sensor no ve luz'),
                    const SizedBox(height: 14),
                    TextField(
                        controller: threshold,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Valor para reconocer la luz',
                            helperText: 'Elige un número de 100 a 3995')),
                    const SizedBox(height: 8),
                    OutlinedButton(
                        onPressed: rx != null && !c.working
                            ? () => c.setThreshold(
                                int.tryParse(threshold.text) ?? -1)
                            : null,
                        child: const Text('Guardar ajuste en el módulo')),
                  ]))),
      const SizedBox(height: 12),
      Card(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle('Brazo robótico',
                        help:
                            'El brazo dibuja el último mensaje que recibió el módulo.\n\nPrimero prepara y ajusta el brazo sin láser. Después apunta a una superficie de prueba, nunca a los ojos. El dibujo aparece punto a punto: una foto de larga exposición puede guardarlo completo.\n\nDetener brazo apaga el láser y detiene el dibujo. También se detiene si pierde la conexión.'),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                        onPressed: rx != null &&
                                !c.working &&
                                status['robotBusy'] != true
                            ? c.drawLastMessage
                            : null,
                        icon: const Icon(Icons.draw_outlined),
                        label: const Text('Dibujar mensaje')),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                        onPressed: rx != null ? c.stopRobot : null,
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('Detener brazo')),
                  ]))),
    ]);
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.icon, this.title, this.value, this.helpTitle,
      this.helpMessage, this.tint);
  final IconData icon;
  final String title, value, helpTitle, helpMessage;
  final Color tint;
  @override
  Widget build(BuildContext context) => Card(
      margin: EdgeInsets.zero,
      child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: tint, borderRadius: BorderRadius.circular(12)),
                      child:
                          Icon(icon, color: AppTheme.ink(context), size: 23)),
                  const Spacer(),
                  HelpButton(title: helpTitle, message: helpMessage)
                ]),
                const SizedBox(height: 12),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(value,
                    style: const TextStyle(
                        fontSize: 23, fontWeight: FontWeight.w700)),
              ])));
}
