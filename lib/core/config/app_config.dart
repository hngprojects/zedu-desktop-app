import 'package:zedu/core/core.dart';

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.usesMockData,
    this.googleClientId = '',
    this.googleClientSecret = '',
  });

  factory AppConfig.fromEnvironment() {
    const defineUsesMock = String.fromEnvironment('USE_MOCK_DATA');
    const defineClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
    const defineClientSecret = String.fromEnvironment('GOOGLE_CLIENT_SECRET');
    const defineBaseUrl = String.fromEnvironment('API_BASE_URL'); // ADD THIS

    final envUsesMock = dotenv.maybeGet('USE_MOCK_DATA')?.trim();
    final envClientId = dotenv.maybeGet('GOOGLE_CLIENT_ID')?.trim();
    final envClientSecret = dotenv.maybeGet('GOOGLE_CLIENT_SECRET')?.trim();
    final envBaseUrl = dotenv.maybeGet('API_BASE_URL')?.trim(); // ADD THIS

    String apiBaseUrl = defineBaseUrl.isNotEmpty
        ? defineBaseUrl
        : (envBaseUrl != null &&
              envBaseUrl.isNotEmpty &&
              envBaseUrl != 'https://example.com/api')
        ? envBaseUrl
        : '';
    apiBaseUrl = apiBaseUrl.replaceAll('"', '').replaceAll("'", "");

    if (!apiBaseUrl.endsWith('/')) {
      apiBaseUrl += '/';
    }

    final usesMockData = defineUsesMock.isNotEmpty
        ? _parseBool(defineUsesMock, defaultValue: false)
        : envUsesMock != null && envUsesMock.isNotEmpty
        ? _parseBool(envUsesMock, defaultValue: false)
        : false;

    var googleClientId = defineClientId.isNotEmpty
        ? defineClientId
        : (envClientId?.isNotEmpty ?? false)
        ? envClientId!
        : '';

    googleClientId = googleClientId.trim();
    if (googleClientId.startsWith('http://')) {
      googleClientId = googleClientId.substring(7);
    } else if (googleClientId.startsWith('https://')) {
      googleClientId = googleClientId.substring(8);
    }
    if (googleClientId.endsWith('/')) {
      googleClientId = googleClientId.substring(0, googleClientId.length - 1);
    }

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

  String get websocketUrl {
    final uri = Uri.parse(apiBaseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    if (uri.host.contains('zedu.chat')) {
      return '$scheme://${uri.host}/centrifugo/connection/websocket';
    }
    return '$scheme://${uri.host}/connection/websocket';
  }
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
