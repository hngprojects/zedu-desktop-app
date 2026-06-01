import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class AuthNotifier extends Notifier<AuthState> {
  late AuthRepository _repository;
  late SecureStorageService _storage;
  late AuthInterceptor _interceptor;

  static const _tag = 'AuthNotifier';

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    _storage = locator<SecureStorageService>();
    _interceptor = locator<AuthInterceptor>();

    _interceptor.onUnauthorized = () {
      AppLogger.w('Unauthorized — clearing session', tag: _tag);
      state = const AuthState(status: AuthStatus.unauthenticated);
    };
    _restoreSession();
    return const AuthState(status: AuthStatus.unknown);
  }

  Future<void> _restoreSession() async {
    AppLogger.d('Restoring session from storage', tag: _tag);
    final token = await _storage.getAccessToken();
    if (token == null) {
      AppLogger.i('No stored token — unauthenticated', tag: _tag);
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    final result = await _repository.getCurrentUser();
    switch (result) {
      case Success<User>():
        AppLogger.i('Session restored — ${result.value.email}', tag: _tag);
        try {
          await _storage.writeData(
            'cached_user_profile',
            jsonEncode(result.value.toJson()),
          );
        } catch (_) {}
        state = AuthState(status: AuthStatus.authenticated, user: result.value);
      case Failure<User>():
        final error = result.error;
        final isExplicitlyInvalid =
            error.statusCode == 401 ||
            error.statusCode == 403 ||
            error.kind == ApiFailureKind.unauthorized ||
            error.kind == ApiFailureKind.forbidden;

        if (isExplicitlyInvalid) {
          AppLogger.w(
            'Session restore failed (invalid token) — clearing token',
            tag: _tag,
          );
          await _storage.deleteAccessToken();
          try {
            await _storage.writeData('cached_user_profile', '');
          } catch (_) {}
          state = const AuthState(status: AuthStatus.unauthenticated);
        } else {
          AppLogger.w(
            'Session restore failed (network/server error) — checking cache',
            tag: _tag,
          );
          try {
            final cachedUserJson = await _storage.readData(
              'cached_user_profile',
            );
            if (cachedUserJson != null && cachedUserJson.isNotEmpty) {
              final userMap =
                  jsonDecode(cachedUserJson) as Map<String, dynamic>;
              final cachedUser = User.fromJson(userMap);
              AppLogger.i(
                'Offline session restored from cache — ${cachedUser.email}',
                tag: _tag,
              );
              state = AuthState(
                status: AuthStatus.authenticated,
                user: cachedUser,
              );
              return;
            }
          } catch (e) {
            AppLogger.e(
              'Error loading cached user profile',
              tag: _tag,
              error: e,
            );
          }

          state = const AuthState(status: AuthStatus.unauthenticated);
        }
    }
  }

  Future<void> login({required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();
    AppLogger.d('Login attempt — $normalizedEmail', tag: _tag);
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.login(
      email: normalizedEmail,
      password: password,
    );
    switch (result) {
      case Success<AuthSession>():
        AppLogger.i('Login succeeded — token persisted', tag: _tag);
        await _storage.saveAccessToken(result.value.accessToken);
        try {
          await _storage.writeData(
            'cached_user_profile',
            jsonEncode(result.value.user.toJson()),
          );
        } catch (_) {}
        state = AuthState(
          status: AuthStatus.authenticated,
          user: result.value.user,
        );
        ref.invalidate(workspaceProvider);
      // await _verifyPendingInvite();
      case Failure<AuthSession>():
        AppLogger.w('Login rejected — ${result.error.message}', tag: _tag);
        state = state.copyWith(
          isLoading: false,
          error: result.error.friendlyMessage,
        );
    }
  }

  Future<void> verifyMagicLink({required String token}) async {
    AppLogger.d('Magic link verification attempt', tag: _tag);
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.verifyMagicLink(token: token);
    switch (result) {
      case Success<AuthSession>():
        AppLogger.i(
          'Magic link verification succeeded — token persisted',
          tag: _tag,
        );
        await _storage.saveAccessToken(result.value.accessToken);
        try {
          await _storage.writeData(
            'cached_user_profile',
            jsonEncode(result.value.user.toJson()),
          );
        } catch (_) {}
        state = AuthState(
          status: AuthStatus.authenticated,
          user: result.value.user,
        );
      case Failure<AuthSession>():
        AppLogger.w(
          'Magic link verification failed — ${result.error.message}',
          tag: _tag,
        );
        state = state.copyWith(
          isLoading: false,
          error: result.error.friendlyMessage,
        );
    }
  }

  Future<void> logout() async {
    AppLogger.i('Logout — clearing session', tag: _tag);
    await _storage.deleteAccessToken();
    try {
      await _storage.writeData('cached_user_profile', '');
    } catch (_) {}
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    if (state.isLoading) return;

    AppLogger.i("debug");
    AppLogger.i('started rolling', tag: _tag);

    final normalizedEmail = email.trim().toLowerCase();
    AppLogger.d('Sign up attempt — $normalizedEmail', tag: _tag);
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.signUp(
      username: username,
      email: normalizedEmail,
      password: password,
    );
    switch (result) {
      case Success<void>():
        AppLogger.i('Sign up succeeded', tag: _tag);

        await login(email: normalizedEmail, password: password);
      case Failure<void>():
        AppLogger.w('Sign up failed — ${result.error.message}', tag: _tag);
        state = state.copyWith(
          isLoading: false,
          error: result.error.friendlyMessage,
        );
    }
  }

  Future<bool> forgotPassword({required String email}) async {
    final normalizedEmail = email.trim().toLowerCase();
    AppLogger.d('Forgot password attempt — $normalizedEmail', tag: _tag);
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.forgotPassword(email: normalizedEmail);
    switch (result) {
      case Success<void>():
        AppLogger.i('Forgot password email sent', tag: _tag);
        state = state.copyWith(isLoading: false);
        return true;
      case Failure<void>():
        AppLogger.w(
          'Forgot password failed — ${result.error.message}',
          tag: _tag,
        );
        state = state.copyWith(
          isLoading: false,
          error: result.error.friendlyMessage,
        );
        return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    AppLogger.d('Reset password attempt', tag: _tag);
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.resetPassword(
      email: normalizedEmail,
      token: token,
      newPassword: newPassword,
    );
    switch (result) {
      case Success<void>():
        AppLogger.i('Reset password succeeded', tag: _tag);
        state = state.copyWith(isLoading: false);
        return true;
      case Failure<void>():
        AppLogger.w(
          'Reset password failed — ${result.error.message}',
          tag: _tag,
        );
        state = state.copyWith(
          isLoading: false,
          error: result.error.friendlyMessage,
        );
        return false;
    }
  }

  Future<bool> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    AppLogger.d('Change password attempt', tag: _tag);
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.changePassword(
      email: normalizedEmail,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    switch (result) {
      case Success<void>():
        AppLogger.i('Change password succeeded', tag: _tag);
        state = state.copyWith(isLoading: false);
        return true;
      case Failure<void>():
        AppLogger.w(
          'Change password failed — ${result.error.message}',
          tag: _tag,
        );
        state = state.copyWith(
          isLoading: false,
          error: result.error.friendlyMessage,
        );
        return false;
    }
  }

  Future<String?> get accessToken => _storage.getAccessToken();

  Future<void> refreshCurrentUser() async {
    final result = await _repository.getCurrentUser();
    switch (result) {
      case Success<User>():
        try {
          await _storage.writeData(
            'cached_user_profile',
            jsonEncode(result.value.toJson()),
          );
        } catch (_) {}
        state = state.copyWith(user: result.value);
      case Failure<User>():
        AppLogger.w(
          'Failed to refresh user — ${result.error.message}',
          tag: _tag,
        );
    }
  }

  Future<void> loginWithGoogle() async {
    AppLogger.d('Google Sign-In attempt', tag: _tag);
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final googleAuthService = locator<GoogleAuthService>();
      final grantCode = await googleAuthService.getGrantCode();

      if (grantCode == null) {
        AppLogger.w('Google Sign-In aborted or code not found', tag: _tag);
        state = state.copyWith(isLoading: false);
        return;
      }

      AppLogger.i(
        'Raw authorization code retrieved successfully, sending to backend',
        tag: _tag,
      );

      final result = await _repository.signInWithGoogle(grantCode: grantCode);
      switch (result) {
        case Success<AuthSession>():
          AppLogger.i('Google Sign-In succeeded — token persisted', tag: _tag);
          await _storage.saveAccessToken(result.value.accessToken);
          try {
            await _storage.writeData(
              'cached_user_profile',
              jsonEncode(result.value.user.toJson()),
            );
          } catch (_) {}
          state = AuthState(
            status: AuthStatus.authenticated,
            user: result.value.user,
          );
        case Failure<AuthSession>():
          AppLogger.w(
            'Google Sign-In rejected — ${result.error.message}',
            tag: _tag,
          );
          state = state.copyWith(
            isLoading: false,
            error: result.error.friendlyMessage,
          );
      }
    } catch (e) {
      AppLogger.e('Google Sign-In failed', tag: _tag, error: e);
      state = state.copyWith(isLoading: false, error: 'Google Sign-In failed');
    }
  }

  Future<bool> changeStatus({
    required String icon,
    required String text,
    required StatusTimeout timeout,
    required bool pauseNotifications,
    required bool online,
  }) async {
    AppLogger.d('changeStatus — "$text" online=$online', tag: _tag);
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.changeStatus(
      icon: icon,
      text: text,
      pauseNotifications: pauseNotifications,
      statusTimeout: timeout.apiValue,
      clearStatus: false,
      online: online,
    );

    switch (result) {
      case Success<void>():
        AppLogger.i('Status changed successfully', tag: _tag);
        final updatedStatus = UserStatus(
          emoji: icon.isEmpty ? null : icon,
          text: text.isEmpty ? null : text,
          expiresAt: _expiryFromTimeout(timeout),
          pauseNotifications: pauseNotifications,
          online: online,
        );
        state = state.copyWith(
          isLoading: false,
          user: state.user?._withStatus(updatedStatus),
        );
        return true;

      case Failure<void>():
        AppLogger.w(
          'Status change failed — ${result.error.message}',
          tag: _tag,
        );
        state = state.copyWith(
          isLoading: false,
          error: result.error.friendlyMessage,
        );
        return false;
    }
  }

  Future<bool> clearStatus() async {
    AppLogger.d('clearStatus', tag: _tag);
    state = state.copyWith(isLoading: true, clearError: true);

    final currentOnline = state.user?.status.online ?? true;
    final result = await _repository.changeStatus(
      icon: '',
      text: '',
      pauseNotifications: false,
      statusTimeout: StatusTimeout.dontRemove.apiValue,
      clearStatus: true,
      online: currentOnline,
    );

    switch (result) {
      case Success<void>():
        state = state.copyWith(
          isLoading: false,
          user: state.user?._withStatus(UserStatus(online: currentOnline)),
        );
        return true;
      case Failure<void>():
        state = state.copyWith(
          isLoading: false,
          error: result.error.friendlyMessage,
        );
        return false;
    }
  }

  Future<void> toggleOnlineStatus() async {
    final currentUser = state.user;
    if (currentUser == null) return;

    final newOnline = !currentUser.status.online;
    AppLogger.d('toggleOnlineStatus → online=$newOnline', tag: _tag);

    final currentStatus = currentUser.status;
    final result = await _repository.changeStatus(
      icon: currentStatus.emoji ?? '',
      text: currentStatus.text ?? '',
      pauseNotifications: currentStatus.pauseNotifications,
      statusTimeout: StatusTimeout.dontRemove.apiValue,
      clearStatus: false,
      online: newOnline,
    );

    if (result is Success<void>) {
      state = state.copyWith(
        user: currentUser._withStatus(
          currentStatus.copyWith(online: newOnline),
        ),
      );
    }
  }

  DateTime? _expiryFromTimeout(StatusTimeout timeout) {
    final now = DateTime.now();
    return switch (timeout) {
      StatusTimeout.thirtyMinutes => now.add(const Duration(minutes: 30)),
      StatusTimeout.oneHour => now.add(const Duration(hours: 1)),
      StatusTimeout.today => DateTime(now.year, now.month, now.day, 23, 59),
      StatusTimeout.thisWeek => now.add(Duration(days: 7 - now.weekday)),
      StatusTimeout.dontRemove => null,
    };
  }
}

extension _UserStatusSwap on User {
  User _withStatus(UserStatus newStatus) => User(
    id: id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    phone: phone,
    username: username,
    isVerified: isVerified,
    isOnboarded: isOnboarded,
    createdAt: createdAt,
    currentOrg: currentOrg,
    currentOrganisationSlug: currentOrganisationSlug,
    avatarUrl: avatarUrl,
    defaultAvatarUrl: defaultAvatarUrl,
    creditBalance: creditBalance,
    subscriptionPlanId: subscriptionPlanId,
    aiCreditsPurchasable: aiCreditsPurchasable,
    status: newStatus,
  );
}
