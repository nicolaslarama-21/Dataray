# Hardware y calibración

## Base elegida

Dos ESP32 DevKit/WROOM (`esp32dev`), BPW34 y dos servos. Pines de ejemplo editables en `firmware/include/AppConfig.h`:

| Elemento | Placa | GPIO |
|---|---|---|
| Control del driver del láser de transmisión | Emisor | 25 |
| Salida de tensión del circuito BPW34 | Receptor | 34 (ADC1) |
| Señal servo horizontal | Receptor | 18 |
| Señal servo vertical | Receptor | 19 |
| Control del driver del láser de dibujo | Receptor | 26 |

Los dos láseres cumplen funciones distintas: el fijo transmite datos; el del brazo dibuja sin alterar la alineación del enlace.

## BPW34

El BPW34 es un fotodiodo de corriente, no un módulo digital. Ver [datasheet de Vishay](https://www.vishay.com/docs/81521/bpw34.pdf). Comprueba la identificación de ánodo/cátodo en el encapsulado.

Como **montaje de banco inicial**, puedes polarizarlo en inversa con cátodo a 3,3 V, ánodo a un nodo de medida y resistencia de 10 kΩ entre ese nodo y GND. Conecta el nodo a GPIO34. Con esta polaridad, más luz aumenta la tensión. El valor de la resistencia es inicial y depende del láser, la distancia y la luz ambiente. Si no hay margen entre luz y oscuridad o hay saturación, usa un amplificador transimpedancia con salida compatible con 3,3 V y ajusta ganancia/filtrado. El firmware no reemplaza ese circuito analógico.

```text
3,3 V ---- cátodo BPW34 ánodo ----+---- GPIO34
                                 |
                               10 kΩ
                                 |
                                GND
```

Mantén siempre la señal ADC en 0..3,3 V; no conectes señales de 5 V. El ADC del ESP32 no es un voltímetro de precisión. El umbral trabaja en cuentas 0..4095. Una capucha opaca alrededor del sensor ayuda a reducir iluminación ambiente. No añadas un filtro RC que elimine los pulsos del enlace (10 ms por bit).

## Láseres y alimentación

Usa módulos con limitación de corriente y driver/transistor o MOSFET compatible con señal de 3,3 V, activo en alto. Nunca alimentes un láser desde un GPIO. Añade resistencia de apagado en la entrada del driver para mantenerlo apagado durante el arranque. Prueba primero con un LED. Evita ojos y superficies reflectantes.

Alimenta ambos servos con una fuente externa adecuada a su corriente de arranque, con GND común al ESP32. No desde el pin 3,3 V. El PWM usa 50 Hz y pulsos conservadores 1000..2000 us, pero confirma los límites reales de tus servos y de la mecánica.

## Secuencia de calibración

1. Desconecta el láser del brazo. Verifica que cada eje puede moverse dentro de 80..100 grados sin chocar; cambia xMin/xMax/yMin/yMax en AppConfig.h antes de ampliar el rango.
2. Enciende el receptor y observa `adc` en Pruebas o en monitor serie.
3. Con el láser fijo apagado registra el ADC ambiental. Con luz continua de prueba registra el ADC iluminado. Escoge un umbral intermedio con margen mayor que la histéresis (80 cuentas a cada lado). La entrada no debe permanecer saturada.
4. Introduce ese umbral en la app. Se mantiene en RAM; para hacerlo valor inicial edita AppConfig.h.
5. Emite una prueba. Si expira, verifica primero ADC, polaridad, alineación, masas y firmware de ambas placas. No interpretes el silencio como BER cero.
6. Envía una palabra corta. Cuando el receptor la muestre, prueba el brazo sobre una superficie mate y registra el trazo con larga exposición.

El texto recibido no se dibuja automáticamente: se inicia con el botón de la app. El trazado es por puntos 5x7, hasta ocho caracteres por fila. Un mensaje largo puede tardar minutos. La geometría usa una aproximación lineal pan/tilt; necesitará calibración de escala, inversión y perspectiva según el brazo. No resuelve cinemática inversa de un brazo de eslabones.

La orden Detener apaga el láser de dibujo y detiene el avance; los servos mantienen el último ángulo. Desconectar BLE también lo detiene. Si se pierden los heartbeats de la app durante 10 segundos, el firmware lo detiene. Para una parada física inmediata corta la alimentación del driver/servos: BLE no es un circuito de parada de emergencia.
