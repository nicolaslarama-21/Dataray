import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'theme/appearance_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/dataray_controller.dart';
import 'repositories/dataray_repository_impl.dart';
import 'repositories/history_store.dart';
import 'screens/shell_screen.dart';
import 'services/ble_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  runApp(const DatarayBootstrap());
}

class DatarayBootstrap extends StatelessWidget {
  const DatarayBootstrap({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
      create: (_) => DatarayController(
          DatarayRepositoryImpl(BleService()), MobileHistoryStore()),
      child: const DatarayApp());
}

class DatarayApp extends StatelessWidget {
  const DatarayApp({super.key, this.appearanceStore});
  final AppearanceStore? appearanceStore;
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
      create: (_) =>
          AppearanceController(appearanceStore ?? MobileAppearanceStore()),
      child: Consumer<AppearanceController>(
          builder: (context, appearance, _) => MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'DataRay',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: appearance.mode,
              home: const ShellScreen())));
}
