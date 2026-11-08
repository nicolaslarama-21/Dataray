> Nota histórica: el icono activo es ahora el predeterminado de Flutter. Consulta docs/UI_REFRESH.md para el diseño vigente y los archivos modificados.

# Apariencia y nuevo icono

La apariencia se cambia desde los tres puntos → Apariencia → Modo claro / Modo oscuro. La elección se guarda en las preferencias privadas de Android o iOS y se recupera al abrir la app. En vistas de prueba sin integración nativa, el cambio funciona en memoria.

Se usan fondos azules, cabecera y navegación azul intenso en modo claro; fondos azul marino y paneles azules en modo oscuro. Los colores de tarjetas, mensajes, campos, botones y ayudas siguen el tema. No aparece la imagen del logo ni una flecha de retroceso en la cabecera.

El botón Atrás del teléfono mantiene el recorrido por las pestañas visitadas. Al llegar a Inicio, dos pulsaciones dentro de dos segundos cierran la app en Android, sin mostrar un aviso.

## Icono activo

Fuente: `assets/branding/dataray_robot_v2.png`. Se generó con la herramienta integrada de imágenes, tomando como guía el brazo negro con láser rojo sobre azul de la referencia del usuario. El recurso anterior permanece como archivo de referencia.

Los tamaños nativos se exportan con `tool/export_branding.ps1`. Se actualizaron los iconos de Android/iOS y las imágenes de arranque. El arranque utiliza un fondo azul marino a juego. Para aplicar recursos y preferencias nativas, recompila e instala la app.

## Prompt utilizado

Create a square mobile app icon for DataRay, closely inspired by the user's reference: a realistic black brushed-metal two-joint robotic arm, compact rectangular laser head on its tip, emitting a vivid thin red laser horizontally toward the right. Premium 3D industrial illustration. Deep navy-to-cobalt blue background, subtle segmented blue circular signal rings behind the arm, restrained cyan rim lighting and red highlights on the arm. The beam carries a few tiny glowing red data squares, no readable text or numbers. Strong recognizable silhouette at small size. Opaque full-bleed square background, no outer rounded frame, no lettering, no watermark. Keep the arm and most of the beam inside the central 65 percent of the square so Android circular launcher masking preserves them. Mechanical arm, not a face or humanoid robot. Polished educational engineering identity. 1024x1024 composition.

## Validación

- 18 pruebas Flutter aprobadas.
- Navegación del sistema sin mensaje ni flecha en pantalla.
- Elección de modo, recuperación de la elección y protección frente a una lectura tardía de preferencias.
- Contraste de al menos 4,5:1 para los pares principales de texto y controles en ambos temas.
- Capturas de Inicio, Pruebas, Chat, Historial y ayudas en oscuro revisadas visualmente, además de Inicio/Pruebas en claro.
- Recursos Android compilados con AAPT2; análisis Dart sin observaciones.

La persistencia se probó con una implementación de almacenamiento en memoria; falta verificar las preferencias y el arranque en teléfonos reales. No se compiló un APK completo ni iOS con Xcode en esta revisión.

