// import 'dart:convert';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

abstract interface class UserProfileRemoteDataSource {
  Future<ProfileAccountModel> getAccount();
  Future<ProfileAccountModel> updateAccount(ProfileAccount account);
  Future<void> deleteAccount({required String password});
  Future<void> uploadAvatar(String filePath);
  Future<void> deleteAvatar();
  Future<NotificationPreferencesModel> getNotificationPreferences();
  Future<NotificationPreferencesModel> updateNotificationPreferences(
    NotificationPreferences preferences,
  );
  Future<List<SecuritySessionModel>> getSecuritySessions();
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<OrganizationProfileModel> getOrganization();
  Future<OrganizationProfileModel> createOrganization({
    required String name,
    required String type,
    required String country,
  });
  Future<OrganizationProfileModel> updateOrganization(
    OrganizationProfile organization,
  );
  Future<void> deleteOrganization(String orgId);
  Future<List<TeamMemberModel>> getTeamMembers({String? orgId});
  Future<TeamMemberModel> inviteMember({
    required String email,
    required String role,
    required String orgId,
    String? userId,
  });
  Future<TeamMemberModel> updateMember(TeamMember member);
  Future<void> removeMember(String memberId);
  Future<List<RolePermissionModel>> getRolesAndPermissions();
  Future<BillingInfoModel> getBillingInfo();
  Future<void> acceptInvitation(String token);
  Future<void> addUserDirectly({
    required String orgId,
    required String userId,
    required String roleId,
  });
}

class UserProfileRemoteDataSourceImpl implements UserProfileRemoteDataSource {
  const UserProfileRemoteDataSourceImpl({
    required AppConfig config,
    required ApiBaseService apiBaseService,
  }) : _apiBaseService = apiBaseService;

  final ApiBaseService _apiBaseService;

  @override
  Future<ProfileAccountModel> getAccount() async {
    final response = await _apiBaseService.get<Map<String, dynamic>>(
      path: ApiEndpoints.getAccount,
    );
    final data = response.data['data'];
    return ProfileAccountModel.fromJson(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  @override
  Future<void> addUserDirectly({
    required String orgId,
    required String userId,
    required String roleId,
  }) async {
    await _apiBaseService.post<Map<String, dynamic>>(
      path: '/organisations/$orgId/users',
      data: {'user_id': userId, 'role_Id': roleId},
    );
  }

  @override
  Future<ProfileAccountModel> updateAccount(ProfileAccount account) async {
    final parts = account.name.split(' ');
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final formData = FormData.fromMap({
      'first_name': firstName,
      'last_name': lastName,
      'full_name': account.name,
      'email': account.email,
      'username': account.username,
      'display_name': account.displayName,
      'phone': account.phoneNumber,
      'title': account.title,
      'name_pronounciation': account.namePronunciation,
      'timezone': account.timezone,
    });
    final response = await _apiBaseService.patch<Map<String, dynamic>>(
      path: ApiEndpoints.updateAccount,
      data: formData,
    );
    final data = response.data['data'];
    return ProfileAccountModel.fromJson(
      data is Map<String, dynamic>
          ? data
          : ProfileAccountModel(
              name: account.name,
              email: account.email,
              timezone: account.timezone,
              avatarUrl: account.avatarUrl,
              username: account.username,
              displayName: account.displayName,
              phoneNumber: account.phoneNumber,
              title: account.title,
              namePronunciation: account.namePronunciation,
            ).toJson(),
    );
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    await _apiBaseService.post<Map<String, dynamic>>(
      path: '/account/delete-account',
      data: {'password': password},
    );
  }

  @override
  Future<void> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'avatar_file': await MultipartFile.fromFile(filePath),
    });
    await _apiBaseService.patch<Map<String, dynamic>>(
      path: ApiEndpoints.updateAccount,
      data: formData,
    );
  }

  @override
  Future<void> deleteAvatar() async {
    await _apiBaseService.delete<Map<String, dynamic>>(
      path: ApiEndpoints.deleteProfileImage,
    );
  }

  @override
  Future<NotificationPreferencesModel> getNotificationPreferences() async {
    final response = await _apiBaseService.get<Map<String, dynamic>>(
      path: ApiEndpoints.profileNotifications,
    );
    // FIX: was `as Map<String, dynamic>` — hard cast crashes if data is null
    // or any other type. Use a safe is-check instead.
    final data = response.data['data'];
    return NotificationPreferencesModel.fromJson(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  @override
  Future<NotificationPreferencesModel> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    final response = await _apiBaseService.put<Map<String, dynamic>>(
      path: ApiEndpoints.profileNotifications,
      data: NotificationPreferencesModel.fromEntity(preferences).toJson(),
    );
    final data = response.data['data'];
    return NotificationPreferencesModel.fromJson(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  @override
  Future<List<SecuritySessionModel>> getSecuritySessions() async {
    final userResponse = await _apiBaseService.get<Map<String, dynamic>>(
      path: '/users/me',
    );
    final rawUserData = userResponse.data['data'];
    if (rawUserData is! Map<String, dynamic>) return const [];
    final userId = rawUserData['id']?.toString();
    if (userId == null || userId.isEmpty) return const [];

    final response = await _apiBaseService.get<Map<String, dynamic>>(
      path: ApiEndpoints.securitySessions(userId),
    );
    final raw = response.data['data'];
    final data = raw is Map<String, dynamic>
        ? raw['logs'] ?? raw['items'] ?? raw['data'] ?? const <dynamic>[]
        : raw;
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(SecuritySessionModel.fromJson)
        .toList();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiBaseService.put<Map<String, dynamic>>(
      path: ApiEndpoints.securityPassword,
      data: {'old_password': currentPassword, 'new_password': newPassword},
    );
  }

  @override
  Future<OrganizationProfileModel> getOrganization() async {
    final response = await _apiBaseService.get<Map<String, dynamic>>(
      path: ApiEndpoints.profileOrganization,
    );
    final data = response.data['data'];
    if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
      return OrganizationProfileModel.fromJson(
        data.first as Map<String, dynamic>,
      );
    }
    throw ApiFailure(
      message: 'user not a member of organisation',
      kind: ApiFailureKind.client,
    );
  }

  @override
  Future<OrganizationProfileModel> updateOrganization(
    OrganizationProfile organization,
  ) async {
    final response = await _apiBaseService.put<Map<String, dynamic>>(
      path: ApiEndpoints.organization(organization.id),
      data: OrganizationProfileModel(
        id: organization.id,
        name: organization.name,
        natureOfBusiness: organization.natureOfBusiness,
        country: organization.country,
        logoUrl: organization.logoUrl,
      ).toJson(),
    );

    final data = response.data['data'];
    if (data is Map<String, dynamic>) {
      final backendOrg = OrganizationProfileModel.fromJson(data);
      return OrganizationProfileModel(
        id: backendOrg.id.isNotEmpty ? backendOrg.id : organization.id,
        name: backendOrg.name.isNotEmpty ? backendOrg.name : organization.name,
        natureOfBusiness: backendOrg.natureOfBusiness.isNotEmpty
            ? backendOrg.natureOfBusiness
            : organization.natureOfBusiness,
        country: backendOrg.country.isNotEmpty
            ? backendOrg.country
            : organization.country,
        logoUrl: backendOrg.logoUrl ?? organization.logoUrl,
      );
    }

    // If backend doesn't return the organization, return the one we sent
    return OrganizationProfileModel(
      id: organization.id,
      name: organization.name,
      natureOfBusiness: organization.natureOfBusiness,
      country: organization.country,
      logoUrl: organization.logoUrl,
    );
  }

  @override
  Future<OrganizationProfileModel> createOrganization({
    required String name,
    required String type,
    required String country,
  }) async {
    try {
      final response = await _apiBaseService.post<Map<String, dynamic>>(
        path: '/organisations',
        data: {'name': name, 'type': type, 'country': country},
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      return OrganizationProfileModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      if (e is DioException) {
        throw ApiFailure.fromDioException(e);
      }
      throw ApiFailure.unknown(e);
    }
  }

  @override
  Future<void> deleteOrganization(String orgId) async {
    await _apiBaseService.delete<Map<String, dynamic>>(
      path: ApiEndpoints.organization(orgId),
    );
  }

  // @override
  // Future<List<TeamMemberModel>> getTeamMembers({String? orgId}) async {
  //   if (_config.usesMockData) {
  //     List<TeamMemberModel> loadedTeamMembers = [];

  //     if (orgId != null) {
  //       final storage = locator<SecureStorageService>();
  //       final data = await storage.readData('mock_team_members_$orgId');
  //       if (data != null) {
  //         try {
  //           final List<dynamic> decoded = jsonDecode(data) as List<dynamic>;
  //           loadedTeamMembers = decoded
  //               .map((e) => TeamMemberModel.fromJson(e as Map<String, dynamic>))
  //               .toList();
  //         } catch (_) {}
  //       }
  //     }

  //     if (loadedTeamMembers.isNotEmpty) {
  //       return loadedTeamMembers;
  //     }

  //     final list = _members.map(TeamMemberModel.fromJson).toList();

  //     if (list.length < 100) {
  //       final roles = ['User', 'Guess', 'Manager', 'Project Lead'];
  //       for (int i = 1; i <= 1000; i++) {
  //         list.add(
  //           TeamMemberModel(
  //             id: 'member-mock-$i',
  //             email: 'teammate$i@zedu.app',
  //             role: roles[i % roles.length],
  //             dateJoined: 'May ${i % 20 + 1}, 2026',
  //             status: TeamMemberStatus.active,
  //             name: 'Teammate $i',
  //             avatarUrl: null,
  //           ),
  //         );
  //       }
  //     }
  //     return list;
  //   }

  //   if (orgId == null || orgId.length < 36) {
  //     return [];
  //   }

  //   try {
  //     final response = await _apiBaseService.get<Map<String, dynamic>>(
  //       path: '/organisations/$orgId/users',
  //     );
  //     final data = response.data['data'] as List<dynamic>?;
  //     if (data == null) return [];

  //     return data.cast<Map<String, dynamic>>().map((user) {
  //       return TeamMemberModel(
  //         id: user['id'] as String? ?? '',
  //         email: user['email'] as String? ?? '',
  //         role: user['role'] as String? ?? 'User',
  //         dateJoined: user['created_at'] as String? ?? '',
  //         status: TeamMemberStatus.active,
  //         name:
  //             user['name'] as String? ??
  //             user['username'] as String? ??
  //             'Unknown',
  //         avatarUrl: user['avatar_url'] as String?,
  //       );
  //     }).toList();
  //   } catch (e) {
  //     return [];
  //   }
  // }

  @override
  Future<TeamMemberModel> inviteMember({
    required String email,
    required String role,
    required String orgId,
    String? userId,
  }) async {
    final response = await _apiBaseService.post<Map<String, dynamic>>(
      path: ApiEndpoints.invite,
      data: {
        'org_id': orgId,
        'emails': [email],
        'role_id': role,
      },
    );

    final raw = response.data['data'];
    final data = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    final rawInvitations = data['invitations'];
    final invites = rawInvitations is List
        ? rawInvitations
        : (rawInvitations is Map ? [rawInvitations] : <dynamic>[]);

    if (invites.isNotEmpty) {
      final invite = invites.first as Map<String, dynamic>;
      return TeamMemberModel(
        id:
            invite['id'] as String? ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        email: invite['email'] as String? ?? email,
        role: role,
        dateJoined: userId != null ? 'Active' : 'Pending',
        status: userId != null
            ? TeamMemberStatus.active
            : TeamMemberStatus.pending,
        name: email.split('@').first,
      );
    }

    if (userId != null && userId.isNotEmpty) {
      await _apiBaseService.post<Map<String, dynamic>>(
        path: '/organisations/$orgId/users',
        data: {'user_id': userId, 'role_Id': role},
      );
      return TeamMemberModel(
        id: userId,
        email: email,
        role: role,
        dateJoined: DateTime.now().toString(),
        status: TeamMemberStatus.active,
        name: email.split('@').first,
      );
    }

    if (invites.isNotEmpty) {
      final invite = invites.first as Map<String, dynamic>;
      return TeamMemberModel(
        id:
            invite['id'] as String? ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        email: invite['email'] as String? ?? email,
        role: role,
        dateJoined: invite['sent_at'] as String? ?? 'Pending',
        status: TeamMemberStatus.pending,
        name: email.split('@').first,
      );
    }
    return TeamMemberModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      role: role,
      dateJoined: 'Pending',
      status: TeamMemberStatus.pending,
      name: email.split('@').first,
    );
  }

  @override
  Future<TeamMemberModel> updateMember(TeamMember member) async {
    final response = await _apiBaseService.patch<Map<String, dynamic>>(
      path: ApiEndpoints.organizationMember(member.id),
      data: {'email': member.email, 'role': member.role},
    );
    final data = response.data['data'];
    return TeamMemberModel.fromJson(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  @override
  Future<void> removeMember(String memberId) async {
    await _apiBaseService.delete<Map<String, dynamic>>(
      path: ApiEndpoints.organizationMember(memberId),
    );
  }

  @override
  Future<List<RolePermissionModel>> getRolesAndPermissions() async {
    final orgResponse = await _apiBaseService.get<Map<String, dynamic>>(
      path: ApiEndpoints.profileOrganization,
    );
    final orgs = orgResponse.data['data'];
    final orgId = orgs is List && orgs.isNotEmpty && orgs.first is Map
        ? (orgs.first as Map)['id'] as String?
        : null;
    if (orgId == null || orgId.isEmpty) return const [];
    final response = await _apiBaseService.get<Map<String, dynamic>>(
      path: ApiEndpoints.organizationRoles(orgId),
    );
    final raw = response.data['data'];
    final data = raw is Map<String, dynamic>
        ? raw['roles'] ?? raw['data'] ?? const <dynamic>[]
        : raw;
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(RolePermissionModel.fromJson)
        .toList();
  }

  @override
  Future<void> acceptInvitation(String token) async {
    throw UnimplementedError();
  }

  @override
  Future<BillingInfoModel> getBillingInfo() async {
    throw UnimplementedError();
  }

  @override
  Future<List<TeamMemberModel>> getTeamMembers({String? orgId}) async {
    if (orgId == null || orgId.isEmpty) {
      return [];
    }

    try {
      final response = await _apiBaseService.get<Map<String, dynamic>>(
        path: '/organisations/$orgId/users',
      );
      
      final raw = response.data['data'];
      // The API might wrap the array in 'users' or 'data', or just return the array directly.
      final data = raw is List ? raw : (raw is Map ? raw['users'] ?? raw['data'] : null);
      
      if (data is! List) return [];

      return data.whereType<Map<String, dynamic>>().map((user) {
        return TeamMemberModel(
          id: user['id'] as String? ?? '',
          email: user['email'] as String? ?? '',
          role: user['role'] as String? ?? 'User',
          dateJoined: user['created_at'] as String? ?? '',
          status: TeamMemberStatus.active,
          name:
              user['name'] as String? ??
              user['username'] as String? ??
              user['email']?.toString().split('@').first ??
              'Unknown',
          avatarUrl: user['avatar_url'] as String?,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
