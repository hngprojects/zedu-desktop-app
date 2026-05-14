import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

abstract interface class UserProfileRemoteDataSource {
  Future<ProfileAccountModel> getAccount();
  Future<ProfileAccountModel> updateAccount(ProfileAccount account);
  Future<void> deleteAccount();
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
  Future<OrganizationProfileModel> updateOrganization(
    OrganizationProfile organization,
  );
  Future<void> deleteOrganization();
  Future<List<TeamMemberModel>> getTeamMembers();
  Future<TeamMemberModel> inviteMember({
    required String email,
    required String role,
  });
  Future<TeamMemberModel> updateMember(TeamMember member);
  Future<void> removeMember(String memberId);
}

class UserProfileRemoteDataSourceImpl implements UserProfileRemoteDataSource {
  const UserProfileRemoteDataSourceImpl({
    required AppConfig config,
    required ApiBaseService apiBaseService,
  }) : _config = config,
       _apiBaseService = apiBaseService;

  final AppConfig _config;
  final ApiBaseService _apiBaseService;

  static const _tag = 'UserProfileRemoteDataSource';

  @override
  Future<ProfileAccountModel> getAccount() async {
    if (_config.usesMockData) return ProfileAccountModel.fromJson(_account);
    final response = await _apiBaseService.get<Map<String, dynamic>>(
      path: '/profile/account',
    );
    return ProfileAccountModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<ProfileAccountModel> updateAccount(ProfileAccount account) async {
    if (_config.usesMockData) {
      AppLogger.d('Using mock data for PATCH /profile/account', tag: _tag);
      return ProfileAccountModel(
        name: account.name,
        email: account.email,
        timezone: account.timezone,
        avatarUrl: account.avatarUrl,
      );
    }
    final response = await _apiBaseService.patch<Map<String, dynamic>>(
      path: '/profile/account',
      data: {
        'name': account.name,
        'email': account.email,
        'timezone': account.timezone,
        'avatar_url': account.avatarUrl,
      },
    );
    return ProfileAccountModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteAccount() async {
    if (_config.usesMockData) return;
    await _apiBaseService.delete<Map<String, dynamic>>(path: '/profile/account');
  }

  @override
  Future<NotificationPreferencesModel> getNotificationPreferences() async {
    if (_config.usesMockData) {
      return NotificationPreferencesModel.fromJson(_notifications);
    }
    final response = await _apiBaseService.get<Map<String, dynamic>>(
      path: '/profile/notifications',
    );
    return NotificationPreferencesModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<NotificationPreferencesModel> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    if (_config.usesMockData) {
      return NotificationPreferencesModel(
        mode: preferences.mode,
        fromTime: preferences.fromTime,
        toTime: preferences.toTime,
        useDesktopSettings: preferences.useDesktopSettings,
        emailNotifications: preferences.emailNotifications,
      );
    }
    final response = await _apiBaseService.patch<Map<String, dynamic>>(
      path: '/profile/notifications',
      data: NotificationPreferencesModel(
        mode: preferences.mode,
        fromTime: preferences.fromTime,
        toTime: preferences.toTime,
        useDesktopSettings: preferences.useDesktopSettings,
        emailNotifications: preferences.emailNotifications,
      ).toJson(),
    );
    return NotificationPreferencesModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<SecuritySessionModel>> getSecuritySessions() async {
    if (_config.usesMockData) {
      return _sessions.map(SecuritySessionModel.fromJson).toList();
    }
    final response = await _apiBaseService.get<Map<String, dynamic>>(
      path: '/profile/security/sessions',
    );
    final data = response.data['data'] as List<dynamic>;
    return data
        .cast<Map<String, dynamic>>()
        .map(SecuritySessionModel.fromJson)
        .toList();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_config.usesMockData) return;
    await _apiBaseService.post<Map<String, dynamic>>(
      path: '/profile/security/password',
      data: {'current_password': currentPassword, 'new_password': newPassword},
    );
  }

  @override
  Future<OrganizationProfileModel> getOrganization() async {
    if (_config.usesMockData) {
      return OrganizationProfileModel.fromJson(_organization);
    }
    final response = await _apiBaseService.get<Map<String, dynamic>>(
      path: '/profile/organization',
    );
    return OrganizationProfileModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<OrganizationProfileModel> updateOrganization(
    OrganizationProfile organization,
  ) async {
    if (_config.usesMockData) {
      return OrganizationProfileModel(
        name: organization.name,
        natureOfBusiness: organization.natureOfBusiness,
        country: organization.country,
      );
    }
    final response = await _apiBaseService.patch<Map<String, dynamic>>(
      path: '/profile/organization',
      data: OrganizationProfileModel(
        name: organization.name,
        natureOfBusiness: organization.natureOfBusiness,
        country: organization.country,
      ).toJson(),
    );
    return OrganizationProfileModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteOrganization() async {
    if (_config.usesMockData) return;
    await _apiBaseService.delete<Map<String, dynamic>>(
      path: '/profile/organization',
    );
  }

  @override
  Future<List<TeamMemberModel>> getTeamMembers() async {
    if (_config.usesMockData) {
      return _members.map(TeamMemberModel.fromJson).toList();
    }
    final response = await _apiBaseService.get<Map<String, dynamic>>(
      path: '/profile/organization/members',
    );
    final data = response.data['data'] as List<dynamic>;
    return data
        .cast<Map<String, dynamic>>()
        .map(TeamMemberModel.fromJson)
        .toList();
  }

  @override
  Future<TeamMemberModel> inviteMember({
    required String email,
    required String role,
  }) async {
    if (_config.usesMockData) {
      return TeamMemberModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        role: role,
        dateJoined: 'Pending',
        status: TeamMemberStatus.pending,
      );
    }
    final response = await _apiBaseService.post<Map<String, dynamic>>(
      path: '/profile/organization/members',
      data: {'email': email, 'role': role},
    );
    return TeamMemberModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<TeamMemberModel> updateMember(TeamMember member) async {
    if (_config.usesMockData) {
      return TeamMemberModel(
        id: member.id,
        email: member.email,
        role: member.role,
        dateJoined: member.dateJoined,
        status: member.status,
      );
    }
    final response = await _apiBaseService.patch<Map<String, dynamic>>(
      path: '/profile/organization/members/${member.id}',
      data: {'email': member.email, 'role': member.role},
    );
    return TeamMemberModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> removeMember(String memberId) async {
    if (_config.usesMockData) return;
    await _apiBaseService.delete<Map<String, dynamic>>(
      path: '/profile/organization/members/$memberId',
    );
  }
}

const _account = {
  'name': 'Anonymous user',
  'email': 'anonymoususer@email.com',
  'timezone': 'Africa/Lagos',
};

const _notifications = {
  'mode': 'allMessages',
  'from_time': '12:00 AM',
  'to_time': '11:00 PM',
  'use_desktop_settings': true,
  'email_notifications': false,
};

const _organization = {
  'name': 'Anonymous user',
  'nature_of_business': 'Design agency',
  'country': 'Nigeria',
};

const _sessions = [
  {
    'device': 'Chrome',
    'location': 'Lagos',
    'date': 'May 8, 2026 1:07 PM',
    'last_active': 'May 8, 2026 3:07 PM',
    'status': 'Active',
  },
  {
    'device': 'Chrome',
    'location': 'Abuja',
    'date': 'May 8, 2026 1:07 PM',
    'last_active': 'May 8, 2026 3:07 PM',
    'status': 'Active',
  },
  {
    'device': 'Chrome',
    'location': 'Uyo',
    'date': 'May 8, 2026 1:07 PM',
    'last_active': 'May 8, 2026 3:07 PM',
    'status': 'Active',
  },
];

const _members = [
  {
    'id': 'member-1',
    'email': 'anonymoususer@gmail.com',
    'role': 'Administrator',
    'date_joined': 'May 3, 2026',
    'status': 'active',
  },
];
