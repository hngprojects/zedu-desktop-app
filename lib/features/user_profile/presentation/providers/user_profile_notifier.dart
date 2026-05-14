import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class UserProfileNotifier extends Notifier<UserProfileState> {
  late final UserProfileRepository _repository;

  @override
  UserProfileState build() {
    _repository = ref.read(userProfileRepositoryProvider);
    _load();
    return const UserProfileState(isLoading: true);
  }

  void selectSection(UserProfileSection section) {
    state = state.copyWith(
      section: section,
      clearError: true,
      clearSuccess: true,
    );
  }

  Future<void> _load() async {
    final accountResult = await _repository.getAccount();
    final notificationResult = await _repository.getNotificationPreferences();
    final securityResult = await _repository.getSecuritySessions();
    final organizationResult = await _repository.getOrganization();
    final teamResult = await _repository.getTeamMembers();

    state = state.copyWith(
      account: _valueOrNull(accountResult),
      notifications: _valueOrNull(notificationResult),
      securitySessions: _valueOrNull(securityResult) ?? const [],
      organization: _valueOrNull(organizationResult),
      teamMembers: _valueOrNull(teamResult) ?? const [],
      isLoading: false,
    );
  }

  T? _valueOrNull<T>(Result<T> result) {
    return switch (result) {
      Success<T>() => result.value,
      Failure<T>() => null,
    };
  }
}
