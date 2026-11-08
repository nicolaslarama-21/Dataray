> Nota histórica: el icono activo es ahora el predeterminado de Flutter. Consulta docs/UI_REFRESH.md para el diseño vigente y los archivos modificados.

# Imagen de DataRay

La ilustración se generó con la herramienta integrada de imágenes el 29 de octubre de 2026. El archivo fuente del proyecto es `assets/branding/dataray_robot.png`.

Se exportaron tamaños para los iconos de Android e iOS y sus pantallas de arranque. Android incluye un icono adaptativo y un tema de inicio específico para Android 12 y posteriores. La aplicación mantiene sus cuatro pestañas y utiliza una paleta azul, lavanda y menta.

Para regenerar los tamaños desde el PNG fuente, ejecuta `tool/export_branding.ps1` en PowerShell con System.Drawing disponible. El script solo escribe dentro del proyecto. No genera otra ilustración ni necesita una clave API.

## Prompt utilizado

Use case: logo-brand. Create a polished square 1024x1024 app icon illustration for DataRay, an educational mobile app that sends words using light and an ESP32 robotic arm. Simple premium soft 3D illustration: a compact friendly two-joint robotic arm on a small rounded base, pointing a clearly visible thin cyan laser beam toward a small upright rounded receiver module. One coherent centered symbol, large silhouette, uncluttered, readable at small launcher-icon size. Cool pastel powder blue, periwinkle and mint, with deep slate outlines and soft dimensional shading. Full-bleed opaque very pale ice-blue background #EFF5FC, no outer rounded-square border (the OS applies its own mask). Keep all meaningful parts inside the central 65% square so circular Android cropping preserves them. No text, no letters, no numbers, no watermark, no phone frame, no UI. A welcoming scientific identity, not a cartoon face. Suitable both as app launcher icon and centered launch splash illustration.

## Comprobaciones del rediseño

- 14 pruebas Flutter aprobadas, incluida navegación hacia atrás, doble pulsación para salir en Android, ayudas y botón fijo con una lista larga.
- Análisis Dart sin observaciones.
- Recursos Android compilados con AAPT2.
- Capturas de Inicio, Pruebas y ayuda revisadas visualmente.
- Catálogo de imágenes iOS y XML de arranque verificados; falta compilar iOS con Xcode y revisar el arranque en dispositivos reales.

Para ver los cambios nativos del icono y el arranque, recompila e instala la app. Los recursos siguen las [opciones de personalización de la pantalla de inicio de Android](https://developer.android.com/develop/ui/views/launch/splash-screen).

