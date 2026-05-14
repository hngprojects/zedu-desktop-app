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

  Future<void> updateAccount(ProfileAccount account) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    final result = await _repository.updateAccount(account);
    switch (result) {
      case Success<ProfileAccount>():
        state = state.copyWith(
          account: result.value,
          isSaving: false,
          successMessage: 'Account information saved successfully.',
        );
      case Failure<ProfileAccount>():
        state = state.copyWith(
          isSaving: false,
          error: result.error.friendlyMessage,
        );
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    final result = await _repository.deleteAccount();
    switch (result) {
      case Success<void>():
        state = state.copyWith(
          isSaving: false,
          successMessage: 'Account deleted successfully.',
        );
      case Failure<void>():
        state = state.copyWith(
          isSaving: false,
          error: result.error.friendlyMessage,
        );
    }
  }

  Future<void> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    final result = await _repository.updateNotificationPreferences(preferences);
    switch (result) {
      case Success<NotificationPreferences>():
        state = state.copyWith(
          notifications: result.value,
          isSaving: false,
          successMessage: 'Notification preferences saved successfully.',
        );
      case Failure<NotificationPreferences>():
        state = state.copyWith(
          isSaving: false,
          error: result.error.friendlyMessage,
        );
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    final result = await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    switch (result) {
      case Success<void>():
        state = state.copyWith(
          isSaving: false,
          successMessage: 'Password updated successfully.',
        );
      case Failure<void>():
        state = state.copyWith(
          isSaving: false,
          error: result.error.friendlyMessage,
        );
    }
  }

  Future<void> updateOrganization(OrganizationProfile organization) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    final result = await _repository.updateOrganization(organization);
    switch (result) {
      case Success<OrganizationProfile>():
        state = state.copyWith(
          organization: result.value,
          isSaving: false,
          successMessage: 'Organization information saved successfully.',
        );
      case Failure<OrganizationProfile>():
        state = state.copyWith(
          isSaving: false,
          error: result.error.friendlyMessage,
        );
    }
  }

  Future<void> deleteOrganization() async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    final result = await _repository.deleteOrganization();
    switch (result) {
      case Success<void>():
        state = state.copyWith(
          isSaving: false,
          successMessage: 'Organization deleted successfully.',
        );
      case Failure<void>():
        state = state.copyWith(
          isSaving: false,
          error: result.error.friendlyMessage,
        );
    }
  }

  Future<void> inviteMember({required String email, required String role}) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    final result = await _repository.inviteMember(email: email, role: role);
    switch (result) {
      case Success<TeamMember>():
        state = state.copyWith(
          teamMembers: [...state.teamMembers, result.value],
          isSaving: false,
          successMessage: 'Invite sent successfully.',
        );
      case Failure<TeamMember>():
        state = state.copyWith(
          isSaving: false,
          error: result.error.friendlyMessage,
        );
    }
  }

  Future<void> updateMember(TeamMember member) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    final result = await _repository.updateMember(member);
    switch (result) {
      case Success<TeamMember>():
        state = state.copyWith(
          teamMembers: [
            for (final current in state.teamMembers)
              current.id == result.value.id ? result.value : current,
          ],
          isSaving: false,
          successMessage: 'Team member updated successfully.',
        );
      case Failure<TeamMember>():
        state = state.copyWith(
          isSaving: false,
          error: result.error.friendlyMessage,
        );
    }
  }

  Future<void> removeMember(String memberId) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    final result = await _repository.removeMember(memberId);
    switch (result) {
      case Success<void>():
        state = state.copyWith(
          teamMembers: [
            for (final member in state.teamMembers)
              if (member.id != memberId) member,
          ],
          isSaving: false,
          successMessage: 'Team member removed successfully.',
        );
      case Failure<void>():
        state = state.copyWith(
          isSaving: false,
          error: result.error.friendlyMessage,
        );
    }
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
