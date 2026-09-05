import 'package:zedu/features/features.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.accessTokenExpiresIn,
    required this.notificationToken,
  });

  final User user;
  final String accessToken;
  final DateTime accessTokenExpiresIn;
  final String notificationToken;
}
