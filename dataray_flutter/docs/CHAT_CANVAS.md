# Chat con lienzo de trayectoria

## Qué incluye

Se conserva Chat como una sola pestaña: arriba aparece el lienzo y el mensaje asociado que recibió el fotodiodo; abajo continúa la conversación y el campo para enviar mensajes. No se añadió una quinta pestaña. Con el teclado abierto o poco espacio, el lienzo se resume en una fila y se puede abrir con Ver lienzo.

El lienzo puede ampliarse, acercarse con gestos, guardarse y abrirse después desde Lienzos guardados. Se conserva como puntos y metadatos en el almacenamiento privado del teléfono, no como una fotografía del láser. Se guardan hasta 20 lienzos; guardar otro conserva los 20 más recientes. Guardar otra vez el mismo lienzo no lo duplica. Las vistas previas se guardan explícitamente como vistas previas.

## Diferencias que muestra la interfaz

- **Vista previa**: dibujo que calcula la app a partir del texto recibido, usando la misma fuente de puntos 5x7 del firmware. No demuestra que el brazo se haya movido.
- **Trayectoria del brazo**: puntos que el receptor ESP32 ordenó dibujar mientras encendía el láser. Es telemetría de las órdenes; no incluye realimentación mecánica ni cámara.
- **Seguimiento externo**: contrato preparado para recibir coordenadas desde otro capturador. No hay conexión con Wii implementada ni reconocimiento de letras.

El BPW34 recibe intensidad de luz y datos ópticos; no produce coordenadas X/Y del punto. En la referencia Wiimote se utiliza una cámara infrarroja para localizar fuentes de luz. Un láser visible no debe darse por compatible con ese capturador sin revisar sensor, óptica y calibración. Ver la [descripción técnica de la cámara IR del Wiimote](https://www.wiibrew.org/wiki/Wiimote#IR_Camera). El video proporcionado no pudo reproducirse directamente desde las herramientas; se consultaron referencias técnicas del sistema.

El usuario eligió implementar por ahora **trayectoria del brazo**.

## Uso

1. Compila y carga el firmware actualizado en el receptor. La app anterior y el enlace óptico siguen usando el mismo servicio BLE y los mismos paquetes de texto.
2. Conecta el receptor a este celular. Envía una palabra por el enlace óptico; al recibirla aparecerá la vista previa en Chat.
3. Con el brazo preparado y calibrado, toca Dibujar. El comando existente pide al receptor dibujar el último mensaje óptico recibido.
4. El receptor envía inicio, puntos y fin del dibujo. La app cambia de Vista previa a Trayectoria del brazo y añade los puntos que recibe.
5. Al terminar toca el icono de guardar. Si hubo desconexión, pérdida de puntos o parada, el lienzo queda marcado como incompleto y se puede guardar así.
6. Abre el icono de colecciones para ver los lienzos guardados, con su texto, fuente y estado. Se conservan al cerrar la app; se borran al desinstalarla.

No se inicia movimiento automáticamente al recibir texto. Los botones Dibujar/Detener reutilizan los controles existentes del brazo.

## Estructura

- `lib/features/canvas/models/laser_canvas.dart`: documento, origen, estado y puntos normalizados.
- `lib/features/canvas/data/canvas_store.dart`: contrato de almacenamiento e integración nativa móvil.
- `lib/features/canvas/data/plotter_font.dart`: vista previa con la fuente del RobotWriter original.
- `lib/features/canvas/controllers/canvas_controller.dart`: recepción, orden de eventos, interrupciones y guardado.
- `lib/features/canvas/widgets/laser_canvas_view.dart`: lienzo vectorial mediante CustomPainter.
- `lib/features/canvas/widgets/canvas_panel.dart`: panel de Chat, visor ampliado y galería.
- `lib/controllers/dataray_controller.dart`: deriva los eventos ya recibidos al controlador de lienzo, sin alterar el transporte BLE.
- `lib/screens/chat_screen.dart`: distribución adaptable de lienzo/conversación.
- Android `MainActivity.kt` e iOS `AppDelegate.swift`: canal privado `dataray/canvases`, archivo JSON atómico independiente del historial de pruebas.
- `firmware/include/RobotWriter.h`: notificaciones de inicio, punto iluminado y finalización/interrupción.
- `firmware/src/main.cpp`: envía esa telemetría como líneas JSON por las notificaciones existentes.

La matriz de puntos, pines, límites y tiempos del brazo no se cambiaron. El transporte BLE, el formato de paquetes ópticos y el cálculo del BER permanecen iguales. No se añadieron paquetes Flutter.

## Eventos BLE adicionales

Se usan el servicio, la característica y la fragmentación NDJSON existentes. El texto del ejemplo corresponde a un mensaje previamente recibido por el fotodiodo:

```json
{"type":"canvas","event":"start","id":1,"seq":0,"source":"servo","messageId":7,"text":"HOLA"}
{"type":"canvas","event":"point","id":1,"seq":1,"x":0.1,"y":0.4,"down":true,"dot":true}
{"type":"canvas","event":"end","id":1,"seq":2,"complete":true}
```

- `id`: identificador local del dibujo del ESP32; `seq`: secuencia desde cero. La app añade un id persistente propio para evitar colisiones después de reinicios.
- `messageId`: id óptico del texto dibujado; queda guardado junto al documento.
- `x`, `y`: coordenadas finitas en 0..1; origen arriba a la izquierda.
- `dot:true`: punto aislado de la matriz actual. Para un futuro capturador continuo, `dot:false` une puntos consecutivos con `down:true`; `down:false` levanta el trazo.
- `complete:false`: parada o watchdog; el documento se presenta como incompleto.
- Duplicados y eventos de otra estación/dibujo se ignoran. Un salto de secuencia marca pérdida de datos y evita unir a ciegas segmentos.
- Se limitan los documentos a 4096 puntos. Tras 12 segundos sin puntos/fin, la captura queda incompleta; esto no ordena nuevos movimientos.
- Las coordenadas se dibujan en el plano normalizado actual del firmware: ocho caracteres por fila. No se hacen reconocimiento de escritura, corrección de perspectiva ni simulaciones de captura real.

Un firmware anterior puede seguir enviando/recibiendo mensajes, pero no emite eventos canvas: en ese caso la app solo muestra la vista previa hasta actualizar el receptor.

## Respaldo para volver atrás

El ZIP se creó y comprobó **antes de modificar el proyecto**:

`backups/dataray_antes_lienzo_2026-10-30_164207.zip`

- 220 archivos fuente, 5 663 587 bytes.
- SHA-256: `8d2e2a7076bf56e16e9cb4a08014301c7c5e8dc9fb9a153f34d5d574d9f5a390`.
- Incluye Flutter, Android/iOS, firmware, pruebas, recursos y documentación anteriores al lienzo.
- Excluye únicamente cachés, compilaciones regenerables, repositorio Git y otros respaldos.

Para volver, extrae el ZIP en una carpeta vacía y abre esa carpeta como proyecto. Ejecuta `flutter pub get` y recompila. Evita extraerlo encima de la versión nueva, para que no queden archivos nuevos mezclados. Si ya cargaste el firmware con telemetría, puedes volver a cargar el firmware incluido en el respaldo. El ZIP no contiene los datos privados guardados en el teléfono.

## Verificaciones y límites

- 26 pruebas Flutter aprobadas, incluidas las anteriores, asociación de texto/lienzo, puntos, duplicados, secuencias perdidas, desconexiones, guardado/reapertura y vista con teclado.
- Análisis Dart sin observaciones.
- Prueba C++ del RobotWriter de producción con reloj, GPIO y PWM simulados: inicio, los 18 puntos de A, finalización, parada y watchdog aprobados.
- Prueba C++ del protocolo óptico original aprobada.
- Respaldo ZIP verificado por CRC y SHA-256 después de los cambios. Transporte BLE y protocolo óptico comparados byte a byte contra el respaldo: sin cambios.
- Captura visual del nuevo chat revisada.

La compilación completa del receptor volvió a fallar al iniciar el compilador Xtensa de Windows instalado, antes de compilar el código. Por tanto, no se afirma una compilación ESP32 completa ni una prueba con placas, servos o láseres reales. También queda validar el nuevo archivo privado de lienzos en Android/iOS reales. No se cargó firmware en hardware durante este trabajo.
