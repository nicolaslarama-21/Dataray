# Validación de esta entrega

Fecha: 29 de octubre de 2026.

## Comprobado

- Análisis Dart del proyecto: sin errores, advertencias ni observaciones de lint.
- Suite Flutter: **18 pruebas aprobadas**.
  - Reensamblado de notificaciones BLE fragmentadas y agrupadas.
  - Recuperación después de una línea excesivamente larga.
  - Normalización de alfabeto y límite de mensajes.
  - Fallo de escritura BLE y estado del mensaje.
  - Confirmación de emisión solo desde la estación e id correspondientes.
  - Prueba medida desde receptor, rechazo de id antiguo y guardado sin duplicados.
  - Desconexión durante prueba sin inventar resultado.
  - Navegación por las cuatro pantallas.
  - Pantalla móvil de 360x800 y texto ampliado al 140%, sin desbordes.
- Prueba C++ ejecutada en Windows con MSVC sobre **OpticalProtocol.h de producción**:
  - CRC CCITT-FALSE contra vector de referencia 123456789 → 0x29B1.
  - Ida y vuelta de paquete máximo de 64 bytes.
  - Rechazo de longitud excesiva y detección de corrupción por CRC.
  - Patrón de 184 bits: cero errores intacto, dos errores al invertir dos bits.
  - Resincronización después de reiniciar parser y validación de alfabeto.
- Se comprobaron las firmas BLE utilizadas contra el framework Arduino ESP32 2.0.17 instalado.
- No se agregaron dependencias Flutter ni bibliotecas externas al firmware.

Los tests Flutter usan un repositorio falso; no representan una conexión física. El archivo JSON nativo de Android/iOS y los permisos requieren validación adicional en un teléfono.

## Límite de compilación encontrado

Se intentó `pio run` en ambos perfiles con espressif32 7.1.3 y el framework instalado. El compilador Xtensa de Windows falla al iniciar, incluso al ejecutar `xtensa-esp32-elf-g++.exe --version`, con error de reasignación no válida de DLL del sistema. La compilación completa y los binarios ESP32 **no se pudieron verificar** en este entorno. La prueba C++ del protocolo no sustituye esa compilación.

También falta compilar/instalar el APK y compilar iOS con Xcode. No se cargó firmware en placas, no se movieron motores y no se activaron láseres físicos.

Para respetar la carpeta autorizada, las pruebas se ejecutaron con copias temporales locales de herramientas y cachés. Las copias locales están en .validation, excluidas del control de versiones; no son dependencias del proyecto. Para tu entorno normal usa los comandos del README.

## Verificación pendiente en hardware

1. Compilar con PlatformIO en un entorno donde el compilador Xtensa arranque correctamente.
2. Revisar GPIO y drivers, montar circuito BPW34 y medir los niveles ADC con y sin luz.
3. Verificar permisos y conexión BLE en Android; hacer la misma prueba en iOS si se utiliza.
4. Enviar un mensaje y comprobar texto y CRC en la estación receptora.
5. Medir a varias distancias, incluyendo desconexión, bloqueo del haz y luz ambiente.
6. Guardar historial, cerrar/reabrir la app y verificar persistencia.
7. Calibrar servos sin láser y después probar trazado, parada y watchdog sobre una superficie.

## Reproducir la prueba C++ en Windows

Desde un Developer PowerShell de Visual Studio, ubicado en esta carpeta:

```powershell
New-Item -ItemType Directory -Force firmware/test/build
cl /nologo /EHsc /W4 /I firmware/include firmware/test/protocol_test.cpp /Fo:firmware/test/build/protocol_test.obj /Fe:firmware/test/build/protocol_test.exe
./firmware/test/build/protocol_test.exe
```

Las pruebas Flutter se ejecutan con `flutter test`. Los controles del brazo no son una parada de emergencia eléctrica.


