import 'package:zedu/core/core.dart';
<<<<<<< HEAD
import 'package:zedu/features/features.dart';
import 'package:zedu/app/app.dart';

// import 'package:zedu/features/features.dart';
=======
>>>>>>> origin/dev

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await loadAppEnv();
  setupLocator();

  runApp(const ProviderScope(child: App()));
}
