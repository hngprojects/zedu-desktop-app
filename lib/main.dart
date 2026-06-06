import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  await localNotifier.setup(
    appName: 'Zedu',
    shortcutPolicy: ShortcutPolicy.requireCreate,
  );
  await loadAppEnv();
  setupLocator();

  runApp(const ProviderScope(child: App()));
}
