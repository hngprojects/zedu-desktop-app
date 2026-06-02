import 'package:zedu/core/core.dart';

class GoogleAuthService {
  final String clientId;
  bool _initialized = false;

  GoogleAuthService({required this.clientId});

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await GoogleSignIn.instance.initialize(
        clientId: clientId,
        serverClientId: clientId,
      );
      _initialized = true;
    }
  }

  Future<String?> getGrantCode() async {
    try {
      await _ensureInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      return account.id;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
  }
}
