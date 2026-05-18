// domain/repositories/auth_repository.dart
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

abstract interface class AuthRepository {
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  });
  Future<Result<User>> getCurrentUser();
  Future<Result<void>> signUp({
    required String email,
    required String password,
  });
  Future<Result<void>> forgotPassword({required String email});
  Future<Result<void>> resetPassword({
    required String oldPassword,
    required String newPassword,
  });
}
