import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import 'package:zedu/app/app.dart';

// import 'package:zedu/features/features.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadAppEnv();
  setupLocator();

  runApp(const ProviderScope(child: App()));
}
