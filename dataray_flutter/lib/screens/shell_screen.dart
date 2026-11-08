import '../theme/app_theme.dart';
import '../theme/appearance_picker.dart';
import '../core/user_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/dataray_controller.dart';
import '../navigation/tab_history.dart';
import '../widgets/help.dart';
import 'chat_screen.dart';
import 'diagnostics_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  final tabs = TabHistory();
  DateTime? _lastBack;
  static const labels = ['DataRay', 'Chat', 'Pruebas del enlace', 'Historial'];
  static const icons = [
    Icons.home_rounded,
    Icons.chat_bubble_rounded,
    Icons.bar_chart_rounded,
    Icons.history_rounded
  ];
  void _select(int tab) {
    if (tab == tabs.current) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      tabs.select(tab);
      _lastBack = null;
    });
  }

  Future<void> _back() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (tabs.canGoBack) {
      setState(() {
        tabs.back();
        _lastBack = null;
      });
      return;
    }
    if (Theme.of(context).platform != TargetPlatform.android) return;
    final now = DateTime.now();
    if (_lastBack != null &&
        now.difference(_lastBack!) < const Duration(seconds: 2)) {
      final c = context.read<DatarayController>();
      await c.stopRobot();
      if (!mounted) return;
      await SystemNavigator.pop();
      return;
    }
    _lastBack = now;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<DatarayController>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.systemOverlay(Theme.of(context).colorScheme),
        child: PopScope<Object?>(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _back();
            },
            child: Scaffold(
                appBar: AppBar(
                    automaticallyImplyLeading: false,
                    titleSpacing: 20,
                    title: Row(children: [
                      Icon(icons[tabs.current], size: 22),
                      const SizedBox(width: 10),
                      Flexible(
                          child: Text(labels[tabs.current],
                              overflow: TextOverflow.ellipsis))
                    ]),
                    actions: [
                      PopupMenuButton<String>(
                          tooltip: 'Ayuda y consejos',
                          icon: const Icon(Icons.more_vert_rounded),
                          onSelected: (value) {
                            if (value == 'appearance') {
                              showAppearancePicker(context);
                            } else if (value == 'guide') {
                              showQuickGuide(context);
                            } else {
                              showSimpleHelp(context, 'Acerca de DataRay',
                                  '¡Tus palabras viajan con luz! Un módulo envía el mensaje con un láser y otro lo recibe. El brazo puede dibujarlo sobre una superficie.\n\nEn Android, Atrás regresa por las pestañas que visitaste. Cuando llegues al inicio, presiónalo dos veces para salir.');
                            }
                          },
                          itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: 'appearance',
                                    child: ListTile(
                                        leading: Icon(Icons.palette_outlined),
                                        title: Text('Apariencia'))),
                                PopupMenuItem(
                                    value: 'guide',
                                    child: ListTile(
                                        leading:
                                            Icon(Icons.auto_stories_outlined),
                                        title: Text('Cómo hacer una prueba'))),
                                PopupMenuItem(
                                    value: 'about',
                                    child: ListTile(
                                        leading:
                                            Icon(Icons.info_outline_rounded),
                                        title: Text('Acerca de DataRay'))),
                              ])
                    ]),
                body: SafeArea(
                    top: false,
                    bottom: false,
                    child: Column(children: [
                      if (c.error != null)
                        MaterialBanner(
                            content: Text(userFacingError(c.error!)),
                            leading: const Icon(Icons.info_outline),
                            actions: [
                              TextButton(
                                  onPressed: c.clearError,
                                  child: const Text('Cerrar'))
                            ]),
                      Expanded(
                          child: Center(
                              child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 760),
                                  child: IndexedStack(
                                      index: tabs.current,
                                      children: [
                                        HomeScreen(onTest: () => _select(2)),
                                        const ChatScreen(),
                                        const DiagnosticsScreen(),
                                        const HistoryScreen(),
                                      ])))),
                    ])),
                bottomNavigationBar: DecoratedBox(
                    key: const ValueKey('system-navigation-surface'),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                            top: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant))),
                    child: NavigationBar(
                        selectedIndex: tabs.current,
                        onDestinationSelected: _select,
                        destinations: const [
                          NavigationDestination(
                              icon: Icon(Icons.home_outlined),
                              selectedIcon: Icon(Icons.home_rounded),
                              label: 'Inicio'),
                          NavigationDestination(
                              icon: Icon(Icons.chat_bubble_outline_rounded),
                              selectedIcon: Icon(Icons.chat_bubble_rounded),
                              label: 'Chat'),
                          NavigationDestination(
                              icon: Icon(Icons.bar_chart_outlined),
                              selectedIcon: Icon(Icons.bar_chart_rounded),
                              label: 'Pruebas'),
                          NavigationDestination(
                              icon: Icon(Icons.history_outlined),
                              selectedIcon: Icon(Icons.history_rounded),
                              label: 'Historial'),
                        ])))));
  }
}
