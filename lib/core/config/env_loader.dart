import 'package:zedu/core/core.dart';

/// Loads [dotenv] from project-root env files listed under `flutter.assets`.
///
/// Tries `.env` first (local overrides, gitignored), then `.env.example` so a
/// clean clone still runs. CI must create `.env` before `flutter analyze` / build
/// if `.env` stays in `pubspec.yaml`, or copy from `.env.example`.
Future<void> loadAppEnv() async {
  try {
    await dotenv.load(fileName: '.env');
  } on Object {
    await dotenv.load(fileName: '.env.example');
  }
}
