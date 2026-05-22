import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

abstract interface class AuthRemoteDataSource {
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  });
  Future<UserModel> me();
  Future<void> signUp({required String username, required String email, required String password});
  Future<void> forgotPassword({required String email});
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  });
  Future<void> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl({
    required AppConfig config,
    required ApiBaseService apiBaseService,
  }) : _config = config,
       _apiBaseService = apiBaseService;

  final AppConfig _config;
  final ApiBaseService _apiBaseService;

  static const _tag = 'AuthRemoteDataSource';

  @override
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      if (_config.usesMockData) {
        AppLogger.d('Using mock data for POST /auth/login', tag: _tag);
        if (password != mockPassword) {
          throw const ApiFailure(
            message: 'Invalid credentials',
            kind: ApiFailureKind.client,
          );
        }
        return LoginResponseModel.fromJson(
          LoginResponseModel.mockLoginResponse,
        );
      }

      AppLogger.d('POST /auth/login — $email', tag: _tag);
      final response = await _apiBaseService.post<Map<String, dynamic>>(
        path: 'auth/login',
        data: {'email': email, 'password': password},
      );

      final payload = response.data['data'] as Map<String, dynamic>;
      return LoginResponseModel.fromJson(payload);
    } on ApiFailure {
      rethrow;
    } catch (error) {
      AppLogger.e(
        'Failed to parse /auth/login response',
        tag: _tag,
        error: error,
      );
      throw ApiFailure.fromParsingError(error, path: 'auth/login');
    }
  }

  @override
  Future<UserModel> me() async {
    try {
      if (_config.usesMockData) {
        AppLogger.d('Using mock data for GET /auth/me', tag: _tag);
        final loginResponse = LoginResponseModel.fromJson(
          LoginResponseModel.mockLoginResponse,
        );
        return loginResponse.user;
      }

      AppLogger.d('GET /auth/me', tag: _tag);
      final response = await _apiBaseService.get<Map<String, dynamic>>(
        path: 'auth/me',
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on ApiFailure {
      rethrow;
    } catch (error) {
      AppLogger.e('Failed to parse /auth/me response', tag: _tag, error: error);
      throw ApiFailure.fromParsingError(error, path: 'auth/me');
    }
  }

  @override
  Future<void> signUp({required String username, required String email, required String password}) async {
    try {
      if (_config.usesMockData) {
        AppLogger.d('Using mock data for POST /auth/register', tag: _tag);
        await Future<void>.delayed(const Duration(milliseconds: 800));
        return;
      }

      AppLogger.d('POST auth/register — $email', tag: _tag);
      await _apiBaseService.post<dynamic>(
        path: 'auth/register',
        data: {'username': username, 'email': email, 'password': password},
      );
    } on ApiFailure {
      rethrow;
    } catch (error) {
      AppLogger.e('Failed auth/register', tag: _tag, error: error);
      throw ApiFailure.unknown(error);
    }
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      if (_config.usesMockData) {
        AppLogger.d(
          'Using mock data for POST /auth/forgot-password',
          tag: _tag,
        );
        await Future<void>.delayed(const Duration(milliseconds: 800));
        return;
      }

      AppLogger.d('POST auth/password-reset — $email', tag: _tag);
      await _apiBaseService.post<dynamic>(
        path: 'auth/password-reset',
        data: {'email': email},
      );
    } on ApiFailure {
      rethrow;
    } catch (error) {
      AppLogger.e('Failed auth/password-reset', tag: _tag, error: error);
      throw ApiFailure.unknown(error);
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      if (_config.usesMockData) {
        AppLogger.d(
          'Using mock data for POST /auth/password-reset/verify',
          tag: _tag,
        );
        await Future<void>.delayed(const Duration(milliseconds: 800));
        return;
      }

      AppLogger.d('POST /auth/password-reset/verify', tag: _tag);
      await _apiBaseService.post<dynamic>(
        path: 'auth/password-reset/verify',
        data: {'token': token, 'new_password': newPassword},
      );
    } on ApiFailure {
      rethrow;
    } catch (error) {
      AppLogger.e(
        'Failed /auth/password-reset/verify',
        tag: _tag,
        error: error,
      );
      throw ApiFailure.unknown(error);
    }
  }

  @override
  Future<void> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      if (_config.usesMockData) {
        AppLogger.d('Using mock data for PUT /auth/change-password', tag: _tag);
        await Future<void>.delayed(const Duration(milliseconds: 800));
        return;
      }

      AppLogger.d('PUT /auth/change-password', tag: _tag);
      await _apiBaseService.put<dynamic>(
        path: 'auth/change-password',
        data: {'old_password': oldPassword, 'new_password': newPassword},
      );
    } on ApiFailure {
      rethrow;
    } catch (error) {
      AppLogger.e('Failed /auth/change-password', tag: _tag, error: error);
      throw ApiFailure.unknown(error);
    }
  }
}
