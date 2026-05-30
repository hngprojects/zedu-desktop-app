import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class UserProfileNotifier extends Notifier<UserProfileState> {
  late UserProfileRepository _repository;

  @override
  UserProfileState build() {
    final authStatus = ref.watch(authNotifierProvider.select((s) => s.status));
    final orgId = ref.watch(currentOrgIdProvider);
    _repository = ref.read(userProfileRepositoryProvider);
    if (authStatus == AuthStatus.authenticated) {
      Future.microtask(() => load(orgId: orgId.isNotEmpty ? orgId : null));
      try {
        return state.copyWith(isLoading: true);
      } catch (_) {
        return const UserProfileState(isLoading: true);
      }
    }
    return const UserProfileState(isLoading: false);
  }

  void selectSection(UserProfileSection section) {
    state = state.copyWith(
      section: section,
      clearError: true,
      clearSuccess: true,
    );
  }

  Future<void> updateAccount(ProfileAccount account) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
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
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
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
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
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

  Future<void> revertNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
    final result = await _repository.updateNotificationPreferences(preferences);
    switch (result) {
      case Success<NotificationPreferences>():
        state = state.copyWith(
          notifications: result.value,
          isSaving: false,
          successMessage: 'Changes reverted successfully.',
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
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
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
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
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

  Future<void> createOrganization({
    required String name,
    required String type,
    required String country,
  }) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
    final result = await _repository.createOrganization(
      name: name,
      type: type,
      country: country,
    );
    switch (result) {
      case Success<OrganizationProfile>():
        state = state.copyWith(
          organization: result.value,
          isSaving: false,
          successMessage: 'Organization created successfully.',
        );
        final userId = ref.read(authNotifierProvider).user?.id;
        ref
            .read(workspaceProvider.notifier)
            .addWorkspace(
              Workspace(
                id: result.value.id,
                name: result.value.name,
                avatar: '',
                unreadCount: 0,
                membersCount: 1,
                ownerId: userId,
              ),
            );
      case Failure<OrganizationProfile>():
        state = state.copyWith(
          isSaving: false,
          error: result.error.friendlyMessage,
        );
    }
  }

  Future<void> deleteOrganization() async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
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

  Future<void> leaveOrganization() async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final orgId = ref.read(workspaceProvider).selectedWorkspace?.id;
      final userId = ref.read(authNotifierProvider).user?.id;
      if (orgId == null || userId == null) {
        throw Exception('Missing orgId or userId');
      }

      final api = locator<ApiBaseService>();
      await api.delete<Map<String, dynamic>>(
        path: '/organisations/$orgId/users/$userId',
      );

      ref.read(workspaceProvider.notifier).removeWorkspace(orgId);

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Successfully signed out of workspace.',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to leave workspace. Please try again.',
      );
    }
  }

  Future<String> _getRoleId(String? orgId) async {
    try {
      if (orgId == null) return '019700d8-9085-7f7b-839a-fcbd08b9e26d';
      final api = locator<ApiBaseService>();
      final response = await api.get<Map<String, dynamic>>(
        path: '/organisations/$orgId/roles',
      );
      final data = response.data['data'] as List<dynamic>?;
      if (data != null && data.isNotEmpty) {
        return data.last['id'] as String;
      }
    } catch (e) {}
    return '019700d8-9085-7f7b-839a-fcbd08b9e26d';
  }

  Future<String?> generateInviteLink() async {
    try {
      final api = locator<ApiBaseService>();
      var orgId = ref.read(workspaceProvider).selectedWorkspace?.id;
      if (locator<AppConfig>().usesMockData &&
          (orgId == null || orgId.length < 36)) {
        orgId = '019700db-4e22-7f90-a20e-f9116291ef24';
      }
      final roleId = await _getRoleId(orgId);
      final response = await api.post<Map<String, dynamic>>(
        path: '/invite/general',
        data: {'organisation_id': orgId, 'role_id': roleId},
      );
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null) return null;

      String? token = data['invitation_token']?.toString() ?? data['token']?.toString();
      final link = data['invitation_link']?.toString();

      if (token == null && link != null) {
        final uri = Uri.tryParse(link);
        if (uri != null) {
          token = uri.queryParameters['token'] ?? uri.queryParameters['invitation_token'];
          if (token == null && uri.pathSegments.isNotEmpty) {
            token = uri.pathSegments.last;
          }
        }
      }

      if (token != null) {
        return 'http://staging.zedu.chat/accept_general_invitation?org_id=$orgId&invitation_token=$token';
      }
      return link;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchRegisteredUsers() async {
    try {
      final api = locator<ApiBaseService>();
      final response = await api.get<Map<String, dynamic>>(path: '/users');
      final data = response.data['data'] as List<dynamic>?;
      if (data != null) {
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {}
    return [];
  }

  Future<void> inviteMember({
    required String email,
    required String role,
    String? userId,
  }) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
    var orgId = ref.read(workspaceProvider).selectedWorkspace?.id;
    if (locator<AppConfig>().usesMockData &&
        (orgId == null || orgId.length < 36)) {
      orgId = '019700db-4e22-7f90-a20e-f9116291ef24';
    }

    String roleId = await _getRoleId(orgId);

    if (orgId == null) {
      state = state.copyWith(
        isSaving: false,
        error: 'No active workspace selected to invite members.',
      );
      return;
    }

    final result = await _repository.inviteMember(
      email: email,
      role: roleId,
      orgId: orgId,
      userId: userId,
    );
    switch (result) {
      case Success<TeamMember>():
        final newTeamMembers = [...state.teamMembers, result.value];
        state = state.copyWith(
          teamMembers: newTeamMembers,
          isSaving: false,
          successMessage: 'Invite sent successfully.',
        );

        final config = locator<AppConfig>();
        if (config.usesMockData) {
          final storage = locator<SecureStorageService>();
          final jsonList = newTeamMembers
              .map(
                (m) => {
                  'id': m.id,
                  'email': m.email,
                  'role': m.role,
                  'name': m.name,
                  'avatar_url': m.avatarUrl,
                  'date_joined': m.dateJoined,
                  'status': m.status.name,
                },
              )
              .toList();
          await storage.writeData(
            'mock_team_members_$orgId',
            jsonEncode(jsonList),
          );
        }

      case Failure<TeamMember>():
        if (userId == null) {
          final errStr = result.error.friendlyMessage.toLowerCase();
          if (errStr.contains('exists') ||
              errStr.contains('already') ||
              errStr.contains('conflict') ||
              errStr.contains('registered')) {
            final users = await fetchRegisteredUsers();
            final match = users.firstWhere(
              (u) =>
                  (u['email'] as String?)?.toLowerCase() == email.toLowerCase(),
              orElse: () => <String, dynamic>{},
            );
            final resolvedId = match['id'] as String?;
            if (resolvedId != null && resolvedId.isNotEmpty) {
              final retryResult = await _repository.inviteMember(
                email: email,
                role: roleId,
                orgId: orgId,
                userId: resolvedId,
              );
              if (retryResult is Success<TeamMember>) {
                final newTeamMembers = [
                  ...state.teamMembers,
                  retryResult.value,
                ];
                state = state.copyWith(
                  teamMembers: newTeamMembers,
                  isSaving: false,
                  successMessage: 'User added to organization successfully.',
                );
                return;
              }
            }
          }
        }
        state = state.copyWith(
          isSaving: false,
          error: result.error.friendlyMessage,
        );
    }
  }

  Future<void> updateMember(TeamMember member) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
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
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
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

  Future<void> load({String? orgId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final activeOrgId =
        orgId ?? ref.read(workspaceProvider).selectedWorkspace?.id;
    final results = await Future.wait([
      _repository.getAccount(),
      _repository.getNotificationPreferences(),
      _repository.getSecuritySessions(),
      _repository.getOrganization(),
      _repository.getTeamMembers(orgId: activeOrgId),
      _repository.getRolesAndPermissions(),
      _repository.getBillingInfo(),
    ]);

    if (!ref.mounted) return;

    final accountResult = results[0] as Result<ProfileAccount>;
    final notificationResult = results[1] as Result<NotificationPreferences>;
    final securityResult = results[2] as Result<List<SecuritySession>>;
    final organizationResult = results[3] as Result<OrganizationProfile>;
    final teamResult = results[4] as Result<List<TeamMember>>;
    final rolesResult = results[5] as Result<List<RolePermission>>;
    final billingResult = results[6] as Result<BillingInfo>;

    final error = _getError(results);

    var loadedTeamMembers = _valueOrNull(teamResult) ?? const [];

    if (activeOrgId != null) {
      final storage = locator<SecureStorageService>();
      final data = await storage.readData('mock_team_members_$activeOrgId');
      if (!ref.mounted) return;
      if (data != null) {
        try {
          final List<dynamic> decoded = jsonDecode(data) as List<dynamic>;
          final savedMembers = decoded.map((e) {
            final map = e as Map<String, dynamic>;
            return TeamMember(
              id: (map['id'] as String?) ?? '',
              email: (map['email'] as String?) ?? '',
              role: (map['role'] as String?) ?? '',
              name: map['name'] as String?,
              avatarUrl: map['avatar_url'] as String?,
              dateJoined: (map['date_joined'] as String?) ?? '',
              status: TeamMemberStatus.values.firstWhere(
                (s) => s.name == (map['status'] as String?),
                orElse: () => TeamMemberStatus.active,
              ),
            );
          }).toList();
          loadedTeamMembers = savedMembers;
        } catch (_) {}
      }
    }

    state = state.copyWith(
      account: _valueOrNull(accountResult),
      notifications: _valueOrNull(notificationResult),
      securitySessions: _valueOrNull(securityResult) ?? const [],
      organization: _valueOrNull(organizationResult),
      teamMembers: loadedTeamMembers,
      rolesAndPermissions: _valueOrNull(rolesResult) ?? const [],
      billing: _valueOrNull(billingResult),
      isLoading: false,
      error: error,
    );
  }

  String? _getError(List<dynamic> results) {
    for (final result in results) {
      if (result is Failure) {
        return result.error.friendlyMessage;
      }
    }
    return null;
  }

  T? _valueOrNull<T>(Result<T> result) {
    return switch (result) {
      Success<T>() => result.value,
      Failure<T>() => null,
    };
  }

  Future<void> acceptInvitation(String token) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
    final result = await _repository.acceptInvitation(token);
    switch (result) {
      case Success<void>():
        await ref.read(workspaceProvider.notifier).fetchWorkspaces();
        if (locator<AppConfig>().usesMockData) {
          ref
              .read(workspaceProvider.notifier)
              .addWorkspace(
                Workspace(
                  id: 'joined-workspace-id-${token.hashCode}',
                  name: 'Joined Workspace',
                  avatar: '',
                  unreadCount: 0,
                  membersCount: 5,
                ),
              );
        }
        state = state.copyWith(
          isSaving: false,
          successMessage: 'Successfully joined the workspace.',
        );
      case Failure<void>():
        state = state.copyWith(
          isSaving: false,
          error: result.error.friendlyMessage,
        );
    }
  }
}
