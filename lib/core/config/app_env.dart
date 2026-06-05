import 'dart:convert';

import 'package:flutter/services.dart';

/// Runtime env values loaded from the bundled `.env.json` asset.
class AppEnv {
  AppEnv._();

  static const String assetFileName = '.env.json';

  static final Map<String, String> _values = <String, String>{};
  static bool _isLoaded = false;

  static bool get isLoaded => _isLoaded;

  static String? maybeGet(String key) => _values[key];

  static Future<void> load({String fileName = assetFileName}) async {
    if (_isLoaded) {
      return;
    }
    final String raw = await rootBundle.loadString(fileName);
    _values.addAll(_parseEnvFile(raw));
    _isLoaded = true;
  }

  static Map<String, String> _parseEnvFile(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.startsWith('{')) {
      final Map<String, dynamic> decoded =
          jsonDecode(trimmed) as Map<String, dynamic>;
      return decoded.map(
        (String key, dynamic value) => MapEntry(key, value.toString()),
      );
    }
    final Map<String, String> values = <String, String>{};
    for (final String line in raw.split('\n')) {
      final String cleaned = line.trim();
      if (cleaned.isEmpty || cleaned.startsWith('#')) {
        continue;
      }
      final int separatorIndex = cleaned.indexOf('=');
      if (separatorIndex <= 0) {
        continue;
      }
      final String key = cleaned.substring(0, separatorIndex).trim();
      final String value = cleaned.substring(separatorIndex + 1).trim();
      values[key] = value;
    }
    return values;
  }
}
