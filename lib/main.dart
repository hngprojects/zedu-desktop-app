import 'package:zedu/core/core.dart';
import 'package:zedu/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await localNotifier.setup(
    appName: 'Zedu',
    shortcutPolicy: ShortcutPolicy.requireCreate,
  );
  await loadAppEnv();
  setupLocator();

  runApp(const ProviderScope(child: App()));
}
