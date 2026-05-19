// data/repositories/auth_repository_impl.dart
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required AuthRemoteDataSource remote})
    : _remote = remote;

  final AuthRemoteDataSource _remote;

  static const _tag = 'AuthRepository';

  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remote.login(email: email, password: password);

      AppLogger.i('Login successful — ${response.user.email}', tag: _tag);
      return Success(
        AuthSession(
          user: response.user.toEntity(),
          accessToken: response.accessToken,
          accessTokenExpiresIn: response.accessTokenExpiresIn,
        ),
      );
    } on ApiFailure catch (failure) {
      AppLogger.w('Login failed — ${failure.message}', tag: _tag);
      return Failure(failure);
    } catch (error) {
      AppLogger.e('Unexpected login error', tag: _tag, error: error);
      return Failure(ApiFailure.unknown(error));
    }
  }

  @override
  Future<Result<User>> getCurrentUser() async {
    try {
      final user = await _remote.me();
      AppLogger.i('Current user fetched — ${user.email}', tag: _tag);
      return Success(user.toEntity());
    } on ApiFailure catch (failure) {
      AppLogger.w(
        'Failed to fetch current user — ${failure.message}',
        tag: _tag,
      );
      return Failure(failure);
    } catch (error) {
      AppLogger.e(
        'Unexpected error fetching current user',
        tag: _tag,
        error: error,
      );
      return Failure(ApiFailure.unknown(error));
    }
  }

  @override
  Future<Result<void>> sendMagicLink({required String email}) async {
    try {
      await _remote.sendMagicLink(email: email);
      AppLogger.i('Magic link request sent — $email', tag: _tag);
      return const Success(null);
    } on ApiFailure catch (failure) {
      AppLogger.w('Magic link request failed — ${failure.message}', tag: _tag);
      return Failure(failure);
    } catch (error) {
      AppLogger.e('Unexpected magic link request error', tag: _tag, error: error);
      return Failure(ApiFailure.unknown(error));
    }
  }

  @override
  Future<Result<AuthSession>> verifyMagicLink({required String token}) async {
    try {
      final response = await _remote.verifyMagicLink(token: token);
      AppLogger.i('Magic link verification successful — ${response.user.email}', tag: _tag);
      return Success(
        AuthSession(
          user: response.user.toEntity(),
          accessToken: response.accessToken,
          accessTokenExpiresIn: response.accessTokenExpiresIn,
        ),
      );
    } on ApiFailure catch (failure) {
      AppLogger.w('Magic link verification failed — ${failure.message}', tag: _tag);
      return Failure(failure);
    } catch (error) {
      AppLogger.e('Unexpected magic link verification error', tag: _tag, error: error);
      return Failure(ApiFailure.unknown(error));
    }
  }

  @override
  Future<Result<AuthSession>> signInWithGoogle({
    required String grantCode,
    String? redirectUri,
  }) async {
    try {
      final response = await _remote.signInWithGoogle(
        grantCode: grantCode,
        redirectUri: redirectUri,
      );
      AppLogger.i('Google sign-in successful — ${response.user.email}', tag: _tag);
      return Success(
        AuthSession(
          user: response.user.toEntity(),
          accessToken: response.accessToken,
          accessTokenExpiresIn: response.accessTokenExpiresIn,
        ),
      );
    } on ApiFailure catch (failure) {
      AppLogger.w('Google sign-in failed — ${failure.message}', tag: _tag);
      return Failure(failure);
    } catch (error) {
      AppLogger.e('Unexpected Google sign-in error', tag: _tag, error: error);
      return Failure(ApiFailure.unknown(error));
    }
  }
}
