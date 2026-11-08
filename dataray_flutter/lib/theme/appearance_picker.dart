import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'appearance_controller.dart';

void showAppearancePicker(BuildContext context) {
  showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => Consumer<AppearanceController>(
          builder: (context, appearance, _) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Expanded(
                          child: Text('Elige cómo se ve DataRay',
                              style: TextStyle(
                                  fontSize: 21, fontWeight: FontWeight.w700))),
                      IconButton(
                          tooltip: 'Cerrar apariencia',
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded))
                    ]),
                    const SizedBox(height: 12),
                    for (final option in const [
                      (
                        ThemeMode.light,
                        'Modo claro',
                        Icons.light_mode_outlined
                      ),
                      (ThemeMode.dark, 'Modo oscuro', Icons.dark_mode_outlined),
                    ])
                      Card(
                          child: ListTile(
                              selected: appearance.mode == option.$1,
                              leading: Icon(option.$3),
                              title: Text(option.$2),
                              trailing: Icon(appearance.mode == option.$1
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked),
                              onTap: () {
                                appearance.select(option.$1);
                                Navigator.pop(sheetContext);
                              })),
                  ]))));
}
