# Renovación visual de DataRay

## Resultado

Se conserva Material 3 y la arquitectura existente. No se modificaron controladores, servicios BLE, repositorios, modelos, navegación funcional ni firmware. Se verificaron sus hashes antes y después.

La presentación usa superficies neutras, azul para acciones, contraste en claro/oscuro, tarjetas de radio 16 y controles de radio 12. La barra superior se integra con el fondo; NavigationBar conserva las cuatro pestañas con un fondo uniforme hasta el borde inferior. Inicio mantiene su acceso a Pruebas fijo y reduce el fondo azul del pie.

Historial agrupa visualmente los resultados por fecha, conserva el orden de los registros y muestra hora, distancia, errores y un estado con texto e icono. Cada grupo comparte una tarjeta. El detalle se abre en una hoja desplazable y respeta los márgenes del teléfono. No se agregaron funciones de borrado, filtrado ni cambios de almacenamiento.

## Archivos de presentación modificados

| Archivo | Cambio |
|---|---|
| `lib/theme/app_theme.dart` | ThemeData claro/oscuro, ColorScheme, tipografía, formas, AppBar, NavigationBar, tarjetas y overlays. |
| `lib/main.dart` | Activación visual edge-to-edge en Android antes de dibujar Flutter. Inyección de dependencias sin cambios. |
| `lib/screens/shell_screen.dart` | AnnotatedRegion con overlays del tema, SafeArea lateral y superficie de navegación uniforme hasta el borde inferior. Navegación y callbacks existentes conservados. |
| `lib/screens/home_screen.dart` | Superficies del pie y encabezados de grupos más discretos; búsqueda y conexiones sin cambios. |
| `lib/screens/history_screen.dart` | Agrupación visual por fecha, filas de resultados, estado legible y detalle adaptable. |
| `lib/widgets/common.dart` | Estados vacíos con ancho controlado, textos legibles y un indicador visual moderado. |

## Android y la zona de los botones del sistema

- `systemNavigationBarColor` coincide con el fondo de NavigationBar; se configura también el color transparente del separador.
- `statusBarColor` es transparente y los iconos cambian de brillo según el tema.
- Se desactiva el contraste automático de las barras para evitar el sombreado añadido en navegación de tres botones.
- Scaffold distribuye el espacio y NavigationBar aplica el margen inferior. La app pinta la misma superficie detrás de la zona de gestos/botones; no se añade otra SafeArea alrededor de NavigationBar.
- Android 15/16 puede ignorar el color solicitado para la barra al imponer edge-to-edge. Por eso se resuelve también desde la superficie Flutter y los insets, sin usar una exclusión de edge-to-edge.

Referencias: [Flutter: edge-to-edge](https://docs.flutter.dev/release/breaking-changes/default-systemuimode-edge-to-edge) y [Android: barras e insets](https://developer.android.com/develop/ui/views/layout/edge-to-edge).

Recursos modificados o añadidos dentro de `android/app/src/main/res/`:

- `values/styles.xml`, `values-night/styles.xml`: temas base de arranque y ventana, fondos y brillo de iconos.
- `values/colors.xml`, `values-night/colors.xml`: colores neutros de arranque/navegación y flags de brillo.
- `values-v29/styles.xml`, `values-night-v29/styles.xml`: contraste de barras en Android 10+.
- `values-v31/styles.xml`, `values-night-v31/styles.xml`: arranque Android 12+ con el icono Flutter.
- `drawable/launch_background.xml`, `drawable-v21/launch_background.xml`: fondo sin la ilustración del brazo.
- `mipmap-mdpi/ic_launcher.png`, `mipmap-hdpi/ic_launcher.png`, `mipmap-xhdpi/ic_launcher.png`, `mipmap-xxhdpi/ic_launcher.png`, `mipmap-xxxhdpi/ic_launcher.png`: copias exactas del SDK Flutter instalado.
- Se eliminó `mipmap-anydpi-v26/ic_launcher.xml`, que sustituía esos PNG por el icono personalizado.

No se modificaron permisos, el manifiesto, Gradle ni MainActivity.

## Icono predeterminado de Flutter

El icono ya está restaurado, no solo preparado:

- Android: cinco densidades copiadas de las plantillas del SDK; hashes coincidentes.
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/` usa las imágenes y Contents.json originales. Se restauraron las tres imágenes de LaunchImage.imageset y `ios/Runner/Base.lproj/LaunchScreen.storyboard`. AppDelegate no se modificó.
- `pubspec.yaml`: se retiró la ilustración personalizada del paquete de assets; no cambiaron dependencias.
- `tool/restore_flutter_icon.ps1`: nuevo comando reproducible para recuperar los originales desde el SDK.
- `tool/export_branding.ps1`: entrada compatible que ahora llama al restaurador, evitando volver accidentalmente al brazo.
- Los PNG antiguos del brazo permanecen archivados en assets/branding; ya no se usan.

Desde la raíz del proyecto:

```powershell
./tool/restore_flutter_icon.ps1 -FlutterSdkPath C:/flutter
flutter run
```

Recompila e instala para aplicar los recursos nativos. Un hot reload no reemplaza los iconos del launcher.

Durante la exportación se copiaron también archivos auxiliares `*.png.img.tmpl` al catálogo iOS. Sus variantes PNG correctas fueron restauradas y verificadas por hash; Contents.json referencia los PNG. La revisión automática rechazó borrar los auxiliares porque requería una aprobación deshabilitada. Los auxiliares no se utilizan como iconos; permanece pendiente su limpieza.

## Verificaciones

- 20 pruebas Flutter aprobadas: lógica existente simulada, navegación, temas, contraste, callbacks de dispositivos e Historial.
- Historial probado con resultados, detalle, modo oscuro y cambio de tema en la misma pantalla.
- Insets de 24 px simulados: NavigationBar termina en el borde inferior y ocupa 72 px más el margen del sistema.
- Pantallas pequeñas y texto al 140 % sin desbordes.
- Capturas revisadas visualmente en ambos temas.
- Análisis Dart sin observaciones.
- Recursos Android compilados y enlazados con AAPT2 para comprobar XML y referencias.
- Iconos Android/iOS verificados frente a las plantillas del SDK.

Se actualizaron `test/theme_contrast_test.dart` y se añadió `test/history_presentation_test.dart`. Este informe, README y las notas históricas de apariencia identifican el diseño activo.

No se compiló el APK completo ni iOS con Xcode en esta revisión. Las barras de Android se verificaron con configuración y simulaciones de insets: queda revisar el aspecto final en el teléfono real, tanto con gestos como con tres botones. No se probó hardware BLE real.
