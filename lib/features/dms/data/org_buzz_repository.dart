import 'package:zedu/core/core.dart';

final orgBuzzRepositoryProvider = Provider<OrgBuzzRepository>((ref) {
  return OrgBuzzRepository(locator<ApiBaseService>());
});

class BuzzMember {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? role;

  const BuzzMember({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.role,
  });

  factory BuzzMember.fromJson(Map<String, dynamic> json) {
    return BuzzMember(
      id: (json['user_id'] ?? json['id'] ?? '').toString(),
      name: (json['full_name'] ?? json['username'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String?,
    );
  }
}

class OrgBuzzRepository {
  final ApiBaseService _api;

  OrgBuzzRepository(this._api);

  /// Creates a new org buzz session. Returns Agora token info + buzz metadata.
  Future<Map<String, dynamic>> createOrgBuzz() async {
    final response = await _api.post<Map<String, dynamic>>(
      path: ApiEndpoints.createOrgBuzz,
      data: {},
    );

    final raw = response.data;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    final agoraToken = data['agora_token'] as Map<String, dynamic>?;

    return {
      'buzz_id': data['buzz_id'] ?? data['id'] ?? '',
      'host_id': data['host_id'] ?? '',
      'channel_id': data['channel_id'] ?? '',
      'buzz_code': data['buzz_code'] ?? '',
      'status': data['status'] ?? 'active',
      'token': agoraToken?['token'] ?? '',
      'app_id': agoraToken?['app_id'] ?? '',
      'channel_name': agoraToken?['channel_name'] ?? data['channel_id'] ?? '',
      'uid': agoraToken?['uid'] ?? '',
    };
  }

  /// Joins an existing buzz using a buzzId or buzzCode.
  Future<Map<String, dynamic>> joinBuzzByCode(String codeOrId) async {
    final response = await _api.post<Map<String, dynamic>>(
      path: ApiEndpoints.joinBuzzByCode(codeOrId),
    );

    final raw = response.data;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    final agoraToken = data['agora_token'] as Map<String, dynamic>?;

    return {
      'buzz_id': data['buzz_id'] ?? codeOrId,
      'channel_id': data['channel_id'] ?? '',
      'token': agoraToken?['token'] ?? '',
      'app_id': agoraToken?['app_id'] ?? '',
      'channel_name': agoraToken?['channel_name'] ?? data['channel_id'] ?? '',
      'uid': agoraToken?['uid'] ?? '',
    };
  }

  /// Searches org members that can be invited into a buzz.
  Future<List<BuzzMember>> searchChannelMembers({
    required String channelId,
    required String buzzId,
    required String query,
    int limit = 50,
  }) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        path: ApiEndpoints.searchBuzzMembers,
        data: {
          'channel_id': channelId,
          'buzz_id': buzzId,
          'query': query,
          'limit': limit,
        },
      );
      final raw = response.data;
      final list = (raw['data'] ?? raw['members'] ?? raw['results'] ?? <dynamic>[]) as List<dynamic>;
      return list
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => BuzzMember.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      AppLogger.e('searchChannelMembers failed', tag: 'OrgBuzzRepository', error: e);
      return [];
    }
  }

  /// Invites a list of users into an active buzz.
  Future<bool> inviteUsersToBuzz(String buzzId, List<String> inviteeIds) async {
    try {
      await _api.post<Map<String, dynamic>>(
        path: ApiEndpoints.inviteUsersToBuzz,
        data: {'buzz_id': buzzId, 'invitee_ids': inviteeIds},
      );
      return true;
    } catch (e) {
      AppLogger.e('inviteUsersToBuzz failed', tag: 'OrgBuzzRepository', error: e);
      return false;
    }
  }

  /// Accepts or declines an org buzz invitation.
  Future<bool> respondToOrgBuzzInvitation(String invitationId, bool accept) async {
    try {
      await _api.post<Map<String, dynamic>>(
        path: ApiEndpoints.respondBuzzInvitation,
        data: {'invitation_id': invitationId, 'accept': accept},
      );
      return true;
    } catch (e) {
      AppLogger.e('respondToOrgBuzzInvitation failed', tag: 'OrgBuzzRepository', error: e);
      return false;
    }
  }
}
