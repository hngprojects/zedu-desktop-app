import 'package:zedu/core/core.dart';

Future<void> loadAppEnv() async {
  try {
    await dotenv.load(fileName: '.env');
  } on Object {
    await dotenv.load(fileName: '.env.example');
  }
}
