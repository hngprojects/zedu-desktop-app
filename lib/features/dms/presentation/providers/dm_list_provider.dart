import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final currentOrgIdProvider = Provider<String>((ref) {
  final workspace = ref.watch(workspaceProvider).selectedWorkspace;
  return workspace?.id ?? '';
});

final dmListProvider =
    AsyncNotifierProvider<DmListNotifier, List<DmConversation>>(() {
      return DmListNotifier();
    });

class SelectedDmNotifier extends Notifier<DmConversation?> {
  @override
  DmConversation? build() {
    ref.watch(currentOrgIdProvider);
    return null;
  }

  void select(DmConversation? conversation) {
    state = conversation;
  }
}

final selectedDmProvider =
    NotifierProvider<SelectedDmNotifier, DmConversation?>(
      SelectedDmNotifier.new,
    );

class DmListNotifier extends AsyncNotifier<List<DmConversation>> {
  int _currentPage = 1;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  @override
  Future<List<DmConversation>> build() async {
    final orgId = ref.watch(currentOrgIdProvider);
    if (orgId.isEmpty) return const [];

    _currentPage = 1;
    _hasMore = true;
    return _fetchPage(orgId, 1);
  }

  Future<List<DmConversation>> _fetchPage(String orgId, int page) async {
    final repository = ref.read(dmRepositoryProvider);
    final results = await repository.getConversations(orgId: orgId, page: page);
    if (results.length < DmRepository.pageSize) {
      _hasMore = false;
    }

    if (page == 1) {
      final user = ref.read(authNotifierProvider).user;
      if (user != null) {
        String selfChannelId = '';
        
        try {
          final channelRepo = ref.read(channelRepositoryProvider);
          final channelsResult = await channelRepo.fetchChannels(orgId);
          if (channelsResult is Success<List<Channel>>) {
            final selfChannel = channelsResult.value.firstWhere(
              (c) => c.name == user.username,
              orElse: () => Channel(id: '', name: '', description: '', organisationId: '', ownerId: ''),
            );
            if (selfChannel.id.isNotEmpty) {
              selfChannelId = selfChannel.id;
            }
          }
          // If channel lookup didn't find a valid ID, try creating one
          if (selfChannelId.isEmpty || !DmRepository.isValidChannelId(selfChannelId)) {
            final dmRepo = ref.read(dmRepositoryProvider);
            final created = await dmRepo.createDmChannel(orgId: orgId, userId: user.id);
            selfChannelId = created.channelId;
          }
        } catch (_) {}
        // Last resort: use placeholder (but at least we tried)
        if (selfChannelId.isEmpty) selfChannelId = 'dm_${user.id}_${user.id}';

        final selfConversation = DmConversation(
          channelId: selfChannelId,
          username: '${user.fullname} (You)',
          participantId: user.id,
          previewMessage: 'Saved messages',
          unreadCount: 0,
          avatarUrl: user.avatarUrl,
        );
        // Only add if the backend hasn't already returned it.
        if (!results.any((c) => c.participantId == user.id)) {
          results.insert(0, selfConversation);
        } else {
          // If it exists, make sure its username is correctly suffixed and move it to top
          final idx = results.indexWhere((c) => c.participantId == user.id);
          final existing = results.removeAt(idx);
          results.insert(
            0,
            existing.copyWith(username: '${user.fullname} (You)'),
          );
        }
      }
      
      if (results.isEmpty) {
        return [
          DmConversation(
            channelId: 'mock-channel-id-123',
            username: 'Test User',
            participantId: 'mock-user-id',
            previewMessage:
                'This is a test conversation. Tap to test the composer.',
            unreadCount: 0,
          ),
        ];
      }
    }

    results.sort((a, b) => a.lastActivityAt.compareTo(b.lastActivityAt));

    // Global Notification Subscriptions:
    // Ensure we are listening to real-time events for every active DM.
    final realtimeService = ref.read(realtimeServiceProvider);
    for (final c in results) {
      if (c.channelId.isNotEmpty && !c.channelId.startsWith('mock-')) {
        realtimeService.subscribeToDmChannel(c.channelId);
      }
    }

    return results;
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId.isEmpty) return;

    final current = state.value ?? [];
    _currentPage++;
    final next = await _fetchPage(orgId, _currentPage);
    state = AsyncValue.data([...current, ...next]);
  }

  void addConversation(DmConversation conversation) {
    final current = state.value ?? [];
    if (!current.any((c) => c.channelId == conversation.channelId || c.participantId == conversation.participantId)) {
      state = AsyncValue.data([conversation, ...current]);
    }
  }

  /// Clears the unread badge for a conversation when it is opened.
  void markConversationRead(String channelId) {
    final current = state.value;
    if (current == null) return;

    final idx = current.indexWhere((c) => c.channelId == channelId);
    if (idx == -1 || current[idx].unreadCount == 0) return;

    final updated = List<DmConversation>.from(current);
    updated[idx] = updated[idx].copyWith(unreadCount: 0);
    state = AsyncValue.data(updated);
  }

  Future<void> refresh() async {
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId.isEmpty) return;

    _currentPage = 1;
    _hasMore = true;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPage(orgId, 1));
  }
}

final dmSearchQueryProvider = StateProvider<String>((ref) => '');

final dmSearchResultsProvider = FutureProvider<List<TeamMember>>((ref) async {
  final query = ref.watch(dmSearchQueryProvider).toLowerCase();
  if (query.isEmpty) return [];

  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId.isEmpty) return [];

  final repository = ref.watch(userProfileRepositoryProvider);
  final result = await repository.getTeamMembers(orgId: orgId);
  
  if (result is Success<List<TeamMember>>) {
    return result.value.where((member) {
      final nameMatches = (member.name ?? '').toLowerCase().contains(query);
      final emailMatches = member.email.toLowerCase().contains(query);
      return nameMatches || emailMatches;
    }).toList();
  }
  
  return [];
});
