import 'dart:convert';

/// NDJSON, independent of BLE packet boundaries. ASCII JSON on the wire.
class LineDecoder {
  String _buffer = '';
  bool _discarding = false;
  List<Map<String, dynamic>> add(List<int> bytes) {
    final events = <Map<String, dynamic>>[];
    for (final byte in bytes) {
      if (byte == 10) {
        final line = _buffer;
        final discard = _discarding;
        _buffer = '';
        _discarding = false;
        if (!discard && line.isNotEmpty) {
          final decoded = jsonDecode(line);
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('Evento BLE inválido');
          }
          events.add(decoded);
        }
      } else if (!_discarding) {
        _buffer += String.fromCharCode(byte);
        if (_buffer.length > 512) {
          _buffer = '';
          _discarding = true;
        }
      }
    }
    return events;
  }
}

String normalizeMessage(String input) {
  var text = input.trim().toUpperCase();
  const accents = {
    'Á': 'A',
    'É': 'E',
    'Í': 'I',
    'Ó': 'O',
    'Ú': 'U',
    'Ü': 'U',
    'Ñ': 'N'
  };
  accents.forEach((a, b) => text = text.replaceAll(a, b));
  if (text.isEmpty ||
      text.length > 64 ||
      !RegExp(r'^[A-Z0-9 .,!?-]+$').hasMatch(text)) {
    throw const FormatException(
        'Usa 1–64 caracteres: letras, números y . , ! ? -');
  }
  return text;
}
