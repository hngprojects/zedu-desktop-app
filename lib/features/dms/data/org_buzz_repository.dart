import 'package:zedu/core/core.dart';

final orgBuzzRepositoryProvider = Provider<OrgBuzzRepository>((ref) {
  return OrgBuzzRepository(locator<ApiBaseService>());
});

// ── Models ────────────────────────────────────────────────────────────────────

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
    var name = (json['full_name'] ?? json['username'] ?? json['name'] ?? '').toString();
    if (name.trim().isEmpty) {
      name = '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim();
    }
    return BuzzMember(
      id: (json['user_id'] ?? json['id'] ?? '').toString(),
      name: name,
      email: (json['email'] ?? '').toString(),
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String?,
    );
  }
}

class BuzzInvitation {
  final String invitationId;
  final String buzzId;
  final String channelId;
  final String inviterId;
  final String inviterName;
  final String status;
  final DateTime invitedAt;

  const BuzzInvitation({
    required this.invitationId,
    required this.buzzId,
    required this.channelId,
    required this.inviterId,
    required this.inviterName,
    required this.status,
    required this.invitedAt,
  });

  factory BuzzInvitation.fromJson(Map<String, dynamic> json) {
    return BuzzInvitation(
      invitationId: (json['invitation_id'] ?? '').toString(),
      buzzId: (json['buzz_id'] ?? '').toString(),
      channelId: (json['channel_id'] ?? '').toString(),
      inviterId: (json['inviter_id'] ?? '').toString(),
      inviterName: (json['inviter_name'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      invitedAt: DateTime.tryParse(json['invited_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

// ── Repository ────────────────────────────────────────────────────────────────

class OrgBuzzRepository {
  final ApiBaseService _api;

  OrgBuzzRepository(this._api);

  /// Creates a new org buzz session.
  /// POST /buzz/org/create
  /// Returns Agora token info + buzz metadata.
  Future<Map<String, dynamic>> createOrgBuzz({required String orgId}) async {
    final response = await _api.post<Map<String, dynamic>>(
      path: ApiEndpoints.createOrgBuzz,
      data: {'org_id': orgId},
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

  /// Joins an existing buzz using its ID.
  /// POST /buzz/{id}/join
  Future<Map<String, dynamic>> joinBuzz(String buzzId) async {
    final response = await _api.post<Map<String, dynamic>>(
      path: ApiEndpoints.joinBuzz(buzzId),
    );

    final raw = response.data;
    final data = (raw['data'] ?? raw) as Map<String, dynamic>;
    final agoraToken = data['agora_token'] as Map<String, dynamic>?;

    return {
      'buzz_id': data['buzz_id'] ?? buzzId,
      'channel_id': data['channel_id'] ?? '',
      'token': agoraToken?['token'] ?? '',
      'app_id': agoraToken?['app_id'] ?? '',
      'channel_name': agoraToken?['channel_name'] ?? data['channel_id'] ?? '',
      'uid': agoraToken?['uid'] ?? '',
    };
  }

  /// Joins an existing buzz using a code or link (resolves code to buzzId).
  /// POST /buzz/{id}/join — same endpoint, code IS the id for join by code flow.
  Future<Map<String, dynamic>> joinBuzzByCode(String codeOrId) async {
    final response = await _api.post<Map<String, dynamic>>(
      path: ApiEndpoints.joinBuzz(codeOrId),
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

  /// Searches org members by fetching org users and filtering.
  Future<List<BuzzMember>> searchOrgMembers({
    required String orgId,
    required String query,
  }) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        path: ApiEndpoints.organizationUsers(orgId),
      );
      final raw = response.data;
      final list = (raw['data'] ?? raw['users'] ?? raw['members'] ?? <dynamic>[]) as List<dynamic>;
      
      final lowerQuery = query.toLowerCase();
      
      final members = list
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => BuzzMember.fromJson(Map<String, dynamic>.from(e)));
          
      if (lowerQuery.isEmpty) return members.toList();
      
      return members
          .where((m) => m.name.toLowerCase().contains(lowerQuery) || m.email.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      AppLogger.e('searchOrgMembers failed', tag: 'OrgBuzzRepository', error: e);
      return [];
    }
  }

  /// Searches channel members that can be invited into a buzz.
  /// POST /buzz/search-members
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
          if (channelId.isNotEmpty) 'channel_id': channelId,
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
  /// POST /buzz/invite
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
  /// POST /buzz/invitation/respond
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

  /// Retrieves all pending buzz invitations for the current user.
  /// GET /buzz/invitations/pending
  Future<List<BuzzInvitation>> getPendingInvitations() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        path: ApiEndpoints.getPendingBuzzInvitations,
      );
      final raw = response.data;
      final data = (raw['data'] ?? raw) as Map<String, dynamic>;
      final list = (data['invitations'] ?? <dynamic>[]) as List<dynamic>;
      return list
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => BuzzInvitation.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      AppLogger.e('getPendingInvitations failed', tag: 'OrgBuzzRepository', error: e);
      return [];
    }
  }

  /// Ends an active buzz (host only).
  /// POST /buzz/{id}/end
  Future<bool> endBuzz(String buzzId) async {
    try {
      await _api.post<Map<String, dynamic>>(
        path: ApiEndpoints.endBuzz(buzzId),
      );
      return true;
    } catch (e) {
      AppLogger.e('endBuzz failed', tag: 'OrgBuzzRepository', error: e);
      return false;
    }
  }

  /// Ends all buzz sessions in a channel.
  /// POST /buzz/channel/{channel_id}/end
  Future<bool> endBuzzByChannel(String channelId) async {
    try {
      await _api.post<Map<String, dynamic>>(
        path: ApiEndpoints.endBuzzByChannel(channelId),
      );
      return true;
    } catch (e) {
      AppLogger.e('endBuzzByChannel failed', tag: 'OrgBuzzRepository', error: e);
      return false;
    }
  }

  /// Fetches a fresh Agora RTC token for a buzz session.
  /// POST /buzz/token
  Future<Map<String, dynamic>?> getBuzzToken({
    required String buzzId,
    required String uid,
  }) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        path: ApiEndpoints.getBuzzToken,
        data: {'buzz_id': buzzId, 'uid': uid},
      );
      final raw = response.data;
      return (raw['data'] ?? raw) as Map<String, dynamic>?;
    } catch (e) {
      AppLogger.e('getBuzzToken failed', tag: 'OrgBuzzRepository', error: e);
      return null;
    }
  }
}
