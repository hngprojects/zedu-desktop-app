import 'package:zedu/core/core.dart';

class GoogleAuthService {
  final String clientId;

  GoogleAuthService({required this.clientId});

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: clientId,
    serverClientId: clientId,
    scopes: ['email', 'profile'],
  );

  Future<String?> getGrantCode() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;
      return account.serverAuthCode;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
