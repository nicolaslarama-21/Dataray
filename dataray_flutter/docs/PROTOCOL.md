# Protocolo DataRay v1

## BLE

Servicio Nordic UART compatible en UUID (contrato de datos propio):

| UUID | Uso |
|---|---|
| 6e400001-b5a3-f393-e0a9-e50e24dcca9e | Servicio |
| 6e400002-b5a3-f393-e0a9-e50e24dcca9e | App escribe comandos, con respuesta ATT |
| 6e400003-b5a3-f393-e0a9-e50e24dcca9e | ESP32 notifica eventos |
| 6e400005-b5a3-f393-e0a9-e50e24dcca9e | Lectura de perfil y versión |

Info: `{"protocol":1,"role":"tx"}` o `{"protocol":1,"role":"rx"}`. La app verifica esta lectura, no deduce permisos desde el nombre anunciado. La constante statusUuid de la base anterior queda reservada; los eventos de estado se multiplexan ahora en 003.

Comandos y eventos son líneas JSON ASCII terminadas en LF, divididas en bloques de 20 bytes para soportar MTU 23. Los límites de notificación BLE no son límites de mensaje. La app serializa las escrituras por estación; el ESP32 ensambla cada línea. Comandos: máximo 254 caracteres, JSON plano sin escapes, claves únicas cmd/text/id/value. Los comandos de esta app respetan ese subconjunto. Tramas inválidas se rechazan; las excesivas se descartan hasta LF.

```json
{"cmd":"send","id":123,"text":"HOLA"}
{"cmd":"test","id":124}
{"cmd":"threshold","value":1800}
{"cmd":"draw"}
{"cmd":"stop"}
{"cmd":"ping"}
```

send/test solo en el emisor; threshold/draw en el receptor. stop y ping no producen respuesta. ping renueva el watchdog del brazo. Umbral 100..3995, histéresis ±80. La app pide una conexión BLE sin MTU obligatorio y funciona con fragmentación mínima.

Eventos:

```json
{"type":"tx","id":123}
{"type":"message","id":123,"text":"HOLA"}
{"type":"test","id":124,"bits":184,"errors":0,"crcOk":true}
{"type":"error","id":123,"message":"Optical transmitter busy"}
```

El patrón real es `DATARAY TEST 0123456789`, 23 bytes / 184 bits. status contiene ADC, umbral, luz, ocupación óptica y del brazo, paquetes con CRC válido, fallos CRC, errores de enmarcado UART y eventos descartados. Se notifica cada 1,5 segundos. `tx` significa emisión completada, sin ACK óptico. El receptor solo entrega mensajes de texto con CRC válido. La app espera hasta 20 segundos por la emisión o la prueba; después informa fallo/sin medición, no vuelve a transmitir automáticamente.

## Enlace óptico

OOK binario (encendido=1, apagado=0), no Morse. Se eligió para recuperar paquetes con longitud e integridad verificable. Bit nominal de 10 ms (100 bit/s). UART por software: reposo apagado, inicio encendido, ocho bits LSB primero y dos bits de parada apagados. Se muestrea el centro de cada bit; la tarea óptica tiene prioridad sobre el bucle de presentación/BLE. Cada byte ocupa 110 ms; el mensaje máximo requiere unos 8,2 s, más BLE.

```text
D3 91 | tipo (1 texto, 2 prueba) | id uint32 LE | largo uint8 |
payload ASCII (1..64 bytes) | CRC16 LE
```

CRC16 CCITT-FALSE, polinomio 0x1021, inicio 0xffff. Cubre tipo, id, longitud y payload; no incluye D3 91 ni el CRC. Todo el paquete se descarta si la longitud o el tipo es inválido. El parser se reinicia tras un segundo sin bytes válidos o ante error de bit de parada. El emisor aborta si una tarea retrasa el bit más de un tercio del período.

## Interpretación de pruebas

El receptor compara los bits del payload contra el patrón fijo cuando identifica una trama de prueba con longitud esperada. Devuelve diferencias y cantidad de bits, incluso con CRC erróneo. BER = diferencias / bits comparados. Si se corrompe cabecera, longitud o sincronización, puede no haber resultado: la app muestra timeout. El CRC cubre más campos que el BER del payload; BER cero con CRC inválido es posible. No es una estimación estadística extensa ni contabiliza pérdidas como bits correctos. Usa varias distancias/repeticiones para evaluar el prototipo.

Un solo teléfono puede recibir el resultado porque mantiene ambas conexiones BLE. Con teléfonos separados, el receptor ve el resultado entrante; la orden de prueba desde la pantalla exige ambas estaciones locales para evitar que el emisor espere una respuesta a la que no tiene acceso. El texto normal sí puede enviarse con solo el emisor conectado.

El servicio BLE no tiene emparejamiento autenticado ni cifrado exigido. Esta versión está pensada para banco educativo y control local supervisado. Para distribuir un producto con control físico, se deberá añadir autenticación y vinculación de dispositivos.

Referencias: [ejemplo BLE UART de Espressif para Arduino 2.0.17](https://github.com/espressif/arduino-esp32/blob/2.0.17/libraries/BLE/examples/BLE_uart/BLE_uart.ino), [API y ejemplos flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus).

