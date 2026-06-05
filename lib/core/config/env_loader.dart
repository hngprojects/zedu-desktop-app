import 'package:zedu/core/config/app_env.dart';

/// Loads [AppEnv] from the project-root `.env.json` file bundled under
/// `flutter.assets`.
Future<void> loadAppEnv() async {
  await AppEnv.load();
}
