import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class GroupDM {
  final String id;
  final String name;
  final List<TeamMember> members;
  final int unreadCount;
  final List<String> messages;

  const GroupDM({
    required this.id,
    required this.name,
    required this.members,
    this.unreadCount = 0,
    this.messages = const [],
  });

  GroupDM copyWith({
    String? id,
    String? name,
    List<TeamMember>? members,
    int? unreadCount,
    List<String>? messages,
  }) {
    return GroupDM(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      unreadCount: unreadCount ?? this.unreadCount,
      messages: messages ?? this.messages,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupDM &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          unreadCount == other.unreadCount;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ unreadCount.hashCode;
}

Map<String, dynamic> _teamMemberToJson(TeamMember member) {
  return {
    'id': member.id,
    'email': member.email,
    'role': member.role,
    'dateJoined': member.dateJoined,
    'status': member.status.name,
    'name': member.name,
    'avatarUrl': member.avatarUrl,
  };
}

TeamMember _teamMemberFromJson(Map<String, dynamic> json) {
  return TeamMember(
    id: json['id'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: json['role'] as String? ?? '',
    dateJoined: json['dateJoined'] as String? ?? '',
    status: TeamMemberStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => TeamMemberStatus.active,
    ),
    name: json['name'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
  );
}

Map<String, dynamic> _groupDmToJson(GroupDM group) {
  return {
    'id': group.id,
    'name': group.name,
    'members': group.members.map(_teamMemberToJson).toList(),
    'unreadCount': group.unreadCount,
    'messages': group.messages,
  };
}

GroupDM _groupDmFromJson(Map<String, dynamic> json) {
  return GroupDM(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    members: (json['members'] as List<dynamic>? ?? [])
        .map((m) => _teamMemberFromJson(m as Map<String, dynamic>))
        .toList(),
    unreadCount: json['unreadCount'] as int? ?? 0,
    messages: (json['messages'] as List<dynamic>? ?? [])
        .map((m) => m.toString())
        .toList(),
  );
}

class GroupDmNotifier extends Notifier<List<GroupDM>> {
  final Map<String, List<String>> _offlineQueue = {};
  StreamSubscription<ChatWebsocketMessage>? _wsSubscription;

  @override
  List<GroupDM> build() {
    final orgId = ref.watch(currentOrgIdProvider);
    _listenToWebsockets();
    _listenToNetwork();

    ref.onDispose(() {
      _wsSubscription?.cancel();
    });

    if (orgId.isNotEmpty) {
      Future.microtask(() => _loadCachedGroupDms(orgId));
    }
    return [];
  }

  void _listenToWebsockets() {
    _wsSubscription?.cancel();
    final ws = ref.read(chatWebsocketProvider);
    _wsSubscription = ws.messageStream.listen((msg) {
      final authState = ref.read(authNotifierProvider);
      final currentUser = authState.user;
      final currentUserName = currentUser != null
          ? '${currentUser.firstName} ${currentUser.lastName}'.trim()
          : '';
      final currentUsername = currentUser?.username ?? '';

      final isMe =
          msg.authorName == currentUserName ||
          msg.authorName == currentUsername;
      if (!isMe) {
        _handleIncomingMessage(msg.groupDmId, msg.text);
      }
    });
  }

  void _listenToNetwork() {
    ref.listen<NetworkStatus>(networkStatusProvider, (previous, next) {
      if (next == NetworkStatus.online) {
        _flushOfflineQueue();
      }
    });
  }

  Future<void> _loadCachedGroupDms(String orgId) async {
    final authState = ref.read(authNotifierProvider);
    final userId = authState.user?.id ?? '';
    if (userId.isEmpty) return;

    final key = 'group_dms_${userId}_$orgId';
    try {
      final storage = locator<SecureStorageService>();
      final data = await storage.readData(key);
      if (data != null && data.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(data) as List<dynamic>;
        final List<GroupDM> groups = [];
        for (final item in decoded) {
          final group = _groupDmFromJson(item as Map<String, dynamic>);
          final cachedMsgs = await ref
              .read(chatStorageProvider)
              .getCachedMessages(group.id);
          groups.add(
            group.copyWith(
              messages: cachedMsgs.isNotEmpty ? cachedMsgs : group.messages,
            ),
          );
        }
        state = groups;

        final activeIds = state.map((g) => g.id).toList();
        ref.read(chatWebsocketProvider).connect(activeIds);
      }
    } catch (e, stack) {
      AppLogger.e(
        'Error loading cached group DMs',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> _saveCachedGroupDms() async {
    final orgId = ref.read(workspaceProvider).selectedWorkspace?.id ?? '';
    if (orgId.isEmpty) return;

    final authState = ref.read(authNotifierProvider);
    final userId = authState.user?.id ?? '';
    if (userId.isEmpty) return;

    final key = 'group_dms_${userId}_$orgId';
    try {
      final storage = locator<SecureStorageService>();
      final encoded = jsonEncode(state.map(_groupDmToJson).toList());
      await storage.writeData(key, encoded);
    } catch (e, stack) {
      AppLogger.e('Error saving cached group DMs', error: e, stackTrace: stack);
    }
  }

  void _handleIncomingMessage(String groupId, String text) {
    state = [
      for (final group in state)
        if (group.id == groupId)
          group.copyWith(
            messages: [...group.messages, text],
            unreadCount: group.unreadCount + 1,
          )
        else
          group,
    ];
    _saveCachedGroupDms();
  }

  Future<Result<GroupDM>> createGroupDm(
    List<TeamMember> selectedMembers,
  ) async {
    final orgId = ref.read(workspaceProvider).selectedWorkspace?.id ?? '';
    final participantIds = selectedMembers.map((m) => m.id).toList();

    try {
      final api = locator<ApiBaseService>();
      final response = await api.post<Map<String, dynamic>>(
        path: '/organisations/$orgId/group-dms',
        data: {'chat_type': 'user', 'participants': participantIds},
      );

      final data = response.data['data'] as Map<String, dynamic>?;
      if (data != null) {
        final channelId = data['channel_id'] as String? ?? '';
        final rawParticipants = data['participants'] as List<dynamic>? ?? [];
        final List<TeamMember> members = [];
        for (final p in rawParticipants) {
          if (p is Map<String, dynamic>) {
            members.add(
              TeamMember(
                id: p['user_id'] as String? ?? '',
                email: p['email'] as String? ?? '',
                name:
                    p['username'] as String? ??
                    (p['email'] as String? ?? '').split('@').first,
                role: 'User',
                dateJoined: DateTime.now().toString(),
                status: TeamMemberStatus.active,
                avatarUrl: p['avatar_url'] as String?,
              ),
            );
          }
        }

        final name = members
            .map((m) => m.name ?? m.email.split('@').first)
            .join(', ');

        final newGroup = GroupDM(
          id: channelId,
          name: name,
          members: members,
          unreadCount: 0,
          messages: ['Group DM created.'],
        );

        if (!state.any((g) => g.id == channelId)) {
          state = [...state, newGroup];
          _saveCachedGroupDms();
          ref.read(chatWebsocketProvider).connect([channelId]);
        }

        return Success(newGroup);
      }
      return Failure(ApiFailure(message: 'Invalid response from server'));
    } catch (e) {
      final selectedIds = selectedMembers.map((m) => m.id).toSet();
      for (final group in state) {
        final groupIds = group.members.map((m) => m.id).toSet();
        if (groupIds.length == selectedIds.length &&
            groupIds.containsAll(selectedIds)) {
          return Success(group);
        }
      }

      final name = selectedMembers
          .map((m) => m.name ?? m.email.split('@').first)
          .join(', ');

      final newGroup = GroupDM(
        id: 'group-dm-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        members: selectedMembers,
        unreadCount: 0,
        messages: ['Group DM created with $name.'],
      );

      state = [...state, newGroup];
      _saveCachedGroupDms();

      final activeIds = state.map((g) => g.id).toList();
      ref.read(chatWebsocketProvider).connect(activeIds);

      return Success(newGroup);
    }
  }

  Future<void> sendMessage(String groupDmId, String messageText) async {
    final network = ref.read(networkStatusProvider);

    if (network == NetworkStatus.offline) {
      _offlineQueue.putIfAbsent(groupDmId, () => []).add(messageText);
      state = [
        for (final group in state)
          if (group.id == groupDmId)
            group.copyWith(
              messages: [...group.messages, '$messageText (Pending...)'],
            )
          else
            group,
      ];
      _saveCachedGroupDms();
      return;
    }

    state = [
      for (final group in state)
        if (group.id == groupDmId)
          group.copyWith(messages: [...group.messages, messageText])
        else
          group,
    ];

    await ref.read(chatStorageProvider).appendMessage(groupDmId, messageText);
    _saveCachedGroupDms();

    try {
      final repository = ref.read(dmRepositoryProvider);
      await repository.sendMessage(
        groupDmId,
        messageText,
      );
    } catch (e, stack) {
      AppLogger.e(
        'Error sending Group DM message to server',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> _flushOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;

    await Future<void>.delayed(const Duration(milliseconds: 500));
    _offlineQueue.clear();
  }

  void renameGroupDm(String groupId, String newName) {
    state = [
      for (final group in state)
        if (group.id == groupId) group.copyWith(name: newName) else group,
    ];
    _saveCachedGroupDms();
  }

  Future<bool> addGroupDmParticipants(
    String channelId,
    List<String> userIds,
  ) async {
    try {
      final repository = ref.read(dmRepositoryProvider);
      final responseData = await repository.addGroupDmParticipants(
        channelId,
        userIds,
      );

      final data = responseData['data'] as Map<String, dynamic>?;
      if (data != null) {
        final rawParticipants = data['participants'] as List<dynamic>? ?? [];
        final List<TeamMember> updatedMembers = [];
        for (final p in rawParticipants) {
          if (p is Map<String, dynamic>) {
            updatedMembers.add(
              TeamMember(
                id: p['user_id'] as String? ?? '',
                email: p['email'] as String? ?? '',
                name:
                    p['username'] as String? ??
                    (p['email'] as String).split('@').first,
                role: 'User',
                dateJoined: DateTime.now().toString(),
                status: TeamMemberStatus.active,
                avatarUrl: p['avatar_url'] as String?,
              ),
            );
          }
        }

        state = [
          for (final group in state)
            if (group.id == channelId)
              group.copyWith(members: updatedMembers)
            else
              group,
        ];
        _saveCachedGroupDms();
        return true;
      }
      return false;
    } catch (e) {
      final teamMembers = ref.read(userProfileNotifierProvider).teamMembers;
      final added = teamMembers.where((m) => userIds.contains(m.id)).toList();

      state = [
        for (final group in state)
          if (group.id == channelId)
            group.copyWith(
              members: [
                ...group.members,
                ...added.where(
                  (a) => !group.members.any((existing) => existing.id == a.id),
                ),
              ],
            )
          else
            group,
      ];
      _saveCachedGroupDms();
      return true;
    }
  }
}

final groupDmProvider = NotifierProvider<GroupDmNotifier, List<GroupDM>>(
  GroupDmNotifier.new,
);
