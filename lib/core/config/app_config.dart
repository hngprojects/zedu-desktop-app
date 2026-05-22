import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.usesMockData});

  /// Resolves config after [loadAppEnv] has run in [main] (root `.env` /
  /// `.env.example`, bundled as assets).
  ///
  /// Precedence: `--dart-define` wins, then dotenv keys from those files, then
  /// defaults. See [String.fromEnvironment](https://api.flutter.dev/flutter/dart-ui/String/String.fromEnvironment.html).
  factory AppConfig.fromEnvironment() {
    const defineBaseUrl = String.fromEnvironment('API_BASE_URL');
    const defineUsesMock = String.fromEnvironment('USE_MOCK_DATA');

    final envBaseUrl = dotenv.maybeGet('API_BASE_URL')?.trim();
    final envUsesMock = dotenv.maybeGet('USE_MOCK_DATA')?.trim();

    // Force the Zedu URL regardless of .env to bypass any local misconfiguration
    String apiBaseUrl = 'https://api.staging.zedu.chat/api/v1/';

    apiBaseUrl = apiBaseUrl.replaceAll('"', '').replaceAll("'", "");

    if (!apiBaseUrl.endsWith('/')) {
      apiBaseUrl += '/';
    }

    final usesMockData = defineUsesMock.isNotEmpty
        ? _parseBool(defineUsesMock, defaultValue: false)
        : envUsesMock != null && envUsesMock.isNotEmpty
        ? _parseBool(envUsesMock, defaultValue: false)
        : false; // Changed to false so real backend is used by default

    return AppConfig(apiBaseUrl: apiBaseUrl, usesMockData: usesMockData);
  }

  final String apiBaseUrl;
  final bool usesMockData;
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
