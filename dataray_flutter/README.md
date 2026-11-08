# DataRay

App Flutter para enlazar dos ESP32 mediante luz y BLE. Nombre de la app: **DataRay**; la imagen LUCIA se usó como referencia visual, no como cambio de nombre.

## Qué incluye

- Inicio, chat, pruebas del enlace e historial local (hasta 200 resultados).
- Conexión de un emisor, un receptor o ambos al mismo teléfono. También se puede usar un teléfono por estación.
- Perfil verificado leyendo información del firmware; los nombres anunciados son DATARAY_TX y DATARAY_RX.
- Envío de hasta 64 caracteres, normalizados a mayúsculas y sin tildes. Estados separados: en cola, emitido y recibido.
- ADC y umbral del BPW34, patrón de prueba con BER medido en recepción, CRC y contadores.
- Firmware PlatformIO para `esp32dev`, Arduino, BPW34 y dos servos. Trazado manual del último mensaje recibido, parada por BLE y por pérdida de conexión/heartbeat.

## Estructura sencilla

```text
lib/
  main.dart                  # Inyección de dependencias y tema
  core/                      # UUID, normalización y enmarcado BLE
  models/                    # Entidades Dart sin dependencias BLE
  services/ble_service.dart   # Adaptador de flutter_blue_plus
  repositories/              # Contrato de datos, implementación y almacenamiento
  controllers/               # Estado y casos de uso de la app (ChangeNotifier)
  screens/                   # Las cuatro pantallas
  widgets/                   # Componentes visuales compartidos
firmware/
  platformio.ini             # Entornos transmitter y receiver
  include/AppConfig.h        # Pines, tiempos, ADC y límites mecánicos
  include/OpticalProtocol.h  # Paquetes, CRC y parser de enlace óptico
  include/CommandProtocol.h  # Comandos BLE con JSON plano acotado
  include/RobotWriter.h      # Fuente 5x7 y movimiento no bloqueante
  src/main.cpp               # BLE, tarea óptica y coordinación
  test/                      # Pruebas del protocolo C++
docs/
  HARDWARE.md                # Cableado y puesta en marcha
  PROTOCOL.md                # Contrato entre app y ESP32
  VALIDATION.md              # Verificaciones realizadas y pendientes
```

Flujo: `pantalla → controlador → repositorio → servicio BLE`. El firmware tiene su propio protocolo óptico y controlador del brazo. Para crecer, separa un controlador por funcionalidad cuando el estado lo justifique; evita agregar capas vacías.

La estructura se inspira en la separación UI/datos del ejemplo público [Compass de flutter/samples](https://github.com/flutter/samples/tree/main/compass_app), descrita en el [caso de arquitectura oficial](https://docs.flutter.dev/app-architecture/case-study). Se adaptó al tamaño de este proyecto y al Provider que ya estaba instalado. También se consultó [flutter_architecture_samples](https://github.com/brianegan/flutter_architecture_samples) como referencia de estado y separación de presentación. No se copió el código de esos proyectos.

## Ejecutar la app

En esta carpeta:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

Android e iOS requieren teléfono con BLE. En Android 12+ concede Bluetooth/dispositivos cercanos; en Android anteriores concede ubicación y activa el servicio de ubicación para escanear. En iOS concede Bluetooth. El historial se guarda de forma atómica en el directorio privado de la app mediante un canal nativo; no necesita almacenamiento compartido ni servidor. La desinstalación borra el historial. La app no implementa BLE para escritorio/web.

Se conserva `flutter_blue_plus` y su uso educativo/no lucrativo (`License.nonprofit`). Revisar su [licencia oficial](https://pub.dev/packages/flutter_blue_plus) antes de una distribución comercial. No se incorporaron dependencias nuevas.

## Compilar y cargar ESP32

```powershell
cd firmware
pio run
pio run -e transmitter -t upload --upload-port COM5
pio run -e receiver -t upload --upload-port COM6
pio device monitor --port COM6 --baud 115200
```

Sustituye los puertos por los reales. `platformio.ini` fija espressif32 7.1.3 / Arduino ESP32 2.0.17 para reproducibilidad y mantiene tu configuración: esp32dev, monitor 115200, carga 460800, debug. Cada ESP32 lleva el mismo código compilado con un perfil diferente. No se cargó nada a placas físicas durante esta modificación.

## Primer uso

1. Revisa `docs/HARDWARE.md`, monta el circuito BPW34 y el driver del láser.
2. Carga cada perfil en su placa y busca estaciones desde Inicio.
3. Conecta ambos ESP32 para medir desde un solo celular; o emisor en un celular y receptor en otro para mensajes.
4. En Pruebas observa el ADC y ajusta el umbral con luz y sin luz; el valor aplicado dura hasta reiniciar el receptor.
5. Alinea el láser fijo al fotodiodo. Envía HOLA y comprueba su aparición en el perfil receptor.
6. Envía una prueba y guarda el resultado. La distancia es manual; el RSSI de Inicio es Bluetooth.
7. Calibra los dos ejes mecánicos con el láser de dibujo desconectado. Luego usa Trazar último mensaje.

## Alcance físico

El enlace es de **un solo sentido**: emisor → fotodiodo receptor. Para responder por luz hace falta otro láser/fotodiodo y extender el firmware. La confirmación de emisión no acredita recepción remota. La escritura usa una matriz de puntos 5x7 proyectada sobre una superficie; para registrarla completa usa larga exposición. Dos servos convencionales no ofrecen la velocidad de un proyector galvanométrico: no se promete una palabra estable suspendida en el aire. La app siempre muestra el texto recibido.

Falta validar con el circuito, los servos y las placas reales. Pines y límites son valores iniciales configurables, no una calibración universal.

## Rediseño visual

Inicio agrupa los módulos en una tarjeta redondeada y mantiene fijo el acceso a Pruebas. La app usa colores fríos suaves y ayudas con ? para las medidas y el ajuste del sensor. El menú de tres puntos incluye una guía paso a paso. Atrás recorre las pestañas visitadas; en Android, al llegar al inicio, dos pulsaciones en menos de dos segundos cierran la app sin mostrar avisos. No se muestra una flecha ni el logo en la cabecera. Desde los tres puntos → Apariencia se elige el modo claro u oscuro, que se guarda para la próxima apertura. Los iconos activos vuelven a ser los originales de Flutter en Android e iOS. La ilustración del brazo queda archivada sin uso. Ver docs/APPEARANCE.md para el icono activo, los temas y las verificaciones; docs/BRANDING.md conserva el historial del primer diseño.


## Diseño actual e icono Flutter

La renovación visual actual, las verificaciones y el detalle de archivos modificados están en docs/UI_REFRESH.md. Se usa Material 3 con superficies neutras, NavigationBar uniforme y un Historial agrupado por fecha. Para restaurar nuevamente los iconos originales del SDK se dispone de tool/restore_flutter_icon.ps1. Las imágenes de brazos y las notas anteriores se conservan solo como referencias históricas.


## Lienzo dentro de Chat

Chat muestra arriba el mensaje recibido por el fotodiodo y un lienzo de la trayectoria del brazo. Permite ampliar, guardar y reabrir hasta 20 lienzos. Las vistas previas se identifican claramente. El receptor debe cargar el firmware actualizado para emitir los puntos de dibujo; el transporte BLE y el protocolo óptico se conservan. Guía, eventos y respaldo anterior en docs/CHAT_CANVAS.md.

