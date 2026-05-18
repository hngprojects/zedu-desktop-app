import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.usesMockData,
    this.googleClientId = '764182056638-qtmk2mattvq035th78hjgpe5docu0oh1.apps.googleusercontent.com',
    this.googleClientSecret = '',
  });

  /// Resolves config after [loadAppEnv] has run in [main] (`.env` then
  /// `.env.example` as bundled assets; optional `--dart-define` overrides).
  ///
  /// Precedence: `--dart-define` wins, then dotenv keys from those files, then
  /// defaults. See [String.fromEnvironment](https://api.flutter.dev/flutter/dart-ui/String/String.fromEnvironment.html).
  factory AppConfig.fromEnvironment() {
    const defineBaseUrl = String.fromEnvironment('API_BASE_URL');
    const defineUsesMock = String.fromEnvironment('USE_MOCK_DATA');
    const defineClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
    const defineClientSecret = String.fromEnvironment('GOOGLE_CLIENT_SECRET');

    final envBaseUrl = dotenv.maybeGet('API_BASE_URL')?.trim();
    final envUsesMock = dotenv.maybeGet('USE_MOCK_DATA')?.trim();
    final envClientId = dotenv.maybeGet('GOOGLE_CLIENT_ID')?.trim();
    final envClientSecret = dotenv.maybeGet('GOOGLE_CLIENT_SECRET')?.trim();

    final apiBaseUrl = defineBaseUrl.isNotEmpty
        ? defineBaseUrl
        : (envBaseUrl?.isNotEmpty ?? false)
        ? envBaseUrl!
        : 'https://example.com/api';

    final usesMockData = defineUsesMock.isNotEmpty
        ? _parseBool(defineUsesMock, defaultValue: false)
        : envUsesMock != null && envUsesMock.isNotEmpty
        ? _parseBool(envUsesMock, defaultValue: false)
        : false;

    final googleClientId = defineClientId.isNotEmpty
        ? defineClientId
        : (envClientId?.isNotEmpty ?? false)
        ? envClientId!
        : '764182056638-qtmk2mattvq035th78hjgpe5docu0oh1.apps.googleusercontent.com';

    final googleClientSecret = defineClientSecret.isNotEmpty
        ? defineClientSecret
        : (envClientSecret?.isNotEmpty ?? false)
        ? envClientSecret!
        : '';

    return AppConfig(
      apiBaseUrl: apiBaseUrl,
      usesMockData: usesMockData,
      googleClientId: googleClientId,
      googleClientSecret: googleClientSecret,
    );
  }

  final String apiBaseUrl;
  final bool usesMockData;
  final String googleClientId;
  final String googleClientSecret;
}

bool _parseBool(String raw, {required bool defaultValue}) {
  final normalized = raw.trim().toLowerCase();
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return defaultValue;
}
