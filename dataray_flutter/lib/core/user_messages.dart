/// Keeps device/library details out of the interface while retaining them in
/// the controller for diagnostics. Known device replies have a useful action.
String userFacingError(String source) {
  final text =
      source.replaceFirst(RegExp(r'^(Bad state: |FormatException: )'), '');
  if (text.contains('No optical message received yet')) {
    return 'Primero envía un mensaje al receptor desde Chat.';
  }
  if (text.contains('Robot is busy')) {
    return 'El brazo está dibujando. Espera o toca Detener brazo.';
  }
  if (text.contains('Optical transmitter busy') ||
      text.contains('Optical queue full')) {
    return 'El emisor está enviando un mensaje. Espera un momento.';
  }
  if (text.contains('Threshold') || text.contains('umbral')) {
    return 'Elige un valor para el sensor entre 100 y 3995.';
  }
  if (text.contains('Use 1..64') || text.contains('Usa 1–64')) {
    return 'Escribe de 1 a 64 caracteres. Usa letras, números o estos signos: . , ! ? -';
  }
  if (text.contains('No se calculó BER')) {
    return 'No llegó el resultado. Revisa la conexión y apunta la luz al sensor; luego vuelve a probar.';
  }
  if (text.contains('No se confirmó la emisión')) {
    return 'No pudimos confirmar el envío. Revisa que el emisor siga conectado.';
  }
  if (text.contains('Sin comunicación con el brazo')) {
    return 'Se perdió la conexión con el brazo. Revisa el módulo receptor.';
  }
  if (text.contains('No se pudo leer el historial')) {
    return 'No pudimos abrir tus pruebas guardadas. Intenta abrir la app otra vez.';
  }
  if (text.contains('No se pudo guardar')) {
    return 'No pudimos guardar la prueba. Inténtalo otra vez.';
  }
  if (text.contains('BLE está preparado')) {
    return 'Para conectar los módulos, usa la app en un celular Android o iPhone.';
  }
  if (text.contains('no admite BLE')) {
    return 'Este celular no tiene el Bluetooth que necesitan los módulos.';
  }
  if (text.contains('firmware incompatible')) {
    return 'Este módulo necesita una versión compatible del programa DataRay. Pide ayuda a quien lo preparó.';
  }
  if (text.contains('interrumpida') ||
      text.contains('Bluetooth') ||
      text.contains('se desconectó') ||
      text.contains('Desconéctalo') ||
      text.contains('distancia positiva') ||
      text.contains('Estación desconectada')) {
    return text.replaceAll('Estación desconectada.',
        'El módulo está desconectado. Vuelve a conectarlo desde Inicio.');
  }
  return 'No pudimos completar la acción. Revisa que el módulo esté encendido y conectado, y vuelve a intentarlo.';
}
