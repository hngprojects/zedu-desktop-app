import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

// import 'package:zedu/core/core.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.accessTokenExpiresIn,
  });

  final User user;
  final String accessToken;
  final DateTime accessTokenExpiresIn;
}
