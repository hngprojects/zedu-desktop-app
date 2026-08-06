import 'package:zedu/core/core.dart';

class SecureStorageService {
  SecureStorageService() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';

  File get _fallbackFile {
    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return File('$home/.zedu_token');
  }

  static String? _memToken;

  Future<void> saveAccessToken(String token) async {
    _memToken = token;
    try {
      await _storage.write(
        key: _accessTokenKey,
        value: token,
        mOptions: const MacOsOptions(usesDataProtectionKeychain: false),
      );
    } catch (e) {
      try {
        await _fallbackFile.writeAsString(token);
      } catch (fallbackError) {
        AppLogger.e('Failed to save access token to fallback: $fallbackError');
      }
    }
  }

  Future<String?> getAccessToken() async {
    if (_memToken != null) return _memToken;
    try {
      final token = await _storage.read(
        key: _accessTokenKey,
        mOptions: const MacOsOptions(usesDataProtectionKeychain: false),
      );
      if (token != null) {
        _memToken = token;
        return token;
      }
    } catch (e) {
      AppLogger.e('Secure storage read access token error: $e');
    }

    try {
      if (await _fallbackFile.exists()) {
        final token = await _fallbackFile.readAsString();
        _memToken = token;
        return token;
      }
    } catch (e) {
      AppLogger.e('Fallback read access token error: $e');
    }
    return null;
  }

  Future<void> deleteAccessToken() async {
    _memToken = null;
    try {
      await _storage.delete(
        key: _accessTokenKey,
        mOptions: const MacOsOptions(usesDataProtectionKeychain: false),
      );
    } catch (e) {
      AppLogger.e('Secure storage delete access token error: $e');
    }
    try {
      if (await _fallbackFile.exists()) {
        await _fallbackFile.delete();
      }
    } catch (e) {
      AppLogger.e('Fallback delete access token error: $e');
    }
  }

  Future<void> writeData(String key, String value) async {
    try {
      await _storage.write(
        key: key,
        value: value,
        mOptions: const MacOsOptions(usesDataProtectionKeychain: false),
      );
    } catch (e) {
      try {
        final file = File('${_fallbackFile.parent.path}/.zedu_$key');
        await file.writeAsString(value);
      } catch (fallbackError) {
        AppLogger.e('Failed to save data to fallback: $fallbackError');
      }
    }
  }

  Future<String?> readData(String key) async {
    try {
      final val = await _storage.read(
        key: key,
        mOptions: const MacOsOptions(usesDataProtectionKeychain: false),
      );
      if (val != null) return val;
    } catch (e) {
      AppLogger.e('Secure storage read data error: $e');
    }
    try {
      final file = File('${_fallbackFile.parent.path}/.zedu_$key');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      AppLogger.e('Fallback read data error: $e');
    }
    return null;
  }

  Future<void> clearAll() async {
    _memToken = null;
    try {
      await _storage.deleteAll(
        mOptions: const MacOsOptions(usesDataProtectionKeychain: false),
      );
    } catch (e) {
      AppLogger.e('Secure storage clear all error: $e');
    }
    try {
      final dir = _fallbackFile.parent;
      final entities = dir.listSync();
      for (final entity in entities) {
        if (entity is File && entity.path.contains('.zedu_')) {
          await entity.delete();
        }
      }
      if (await _fallbackFile.exists()) {
        await _fallbackFile.delete();
      }
    } catch (e) {
      AppLogger.e('Fallback clear all error: $e');
    }
  }
}
