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
      } catch (_) {}
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
    } catch (e) {}

    try {
      if (await _fallbackFile.exists()) {
        final token = await _fallbackFile.readAsString();
        _memToken = token;
        return token;
      }
    } catch (_) {}
    return null;
  }

  Future<void> deleteAccessToken() async {
    _memToken = null;
    try {
      await _storage.delete(
        key: _accessTokenKey,
        mOptions: const MacOsOptions(usesDataProtectionKeychain: false),
      );
    } catch (_) {}
    try {
      if (await _fallbackFile.exists()) {
        await _fallbackFile.delete();
      }
    } catch (_) {}
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
      } catch (_) {}
    }
  }

  Future<String?> readData(String key) async {
    try {
      final val = await _storage.read(
        key: key,
        mOptions: const MacOsOptions(usesDataProtectionKeychain: false),
      );
      if (val != null) return val;
    } catch (e) {}
    try {
      final file = File('${_fallbackFile.parent.path}/.zedu_$key');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (_) {}
    return null;
  }

  Future<void> clearAll() async {
    _memToken = null;
    try {
      await _storage.deleteAll(
        mOptions: const MacOsOptions(usesDataProtectionKeychain: false),
      );
    } catch (_) {}
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
    } catch (_) {}
  }
}
