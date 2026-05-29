import 'dart:convert';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  final apiBaseService = locator<ApiBaseService>();
  final remoteDataSource = ChannelRemoteDataSourceImpl(
    apiBaseService: apiBaseService,
  );
  return ChannelRepositoryImpl(remoteDataSource: remoteDataSource);
});

class ChannelState {
  final List<Channel> channels;
  final bool isLoading;
  final String? errorMessage;

  const ChannelState({
    this.channels = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ChannelState copyWith({
    List<Channel>? channels,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ChannelState(
      channels: channels ?? this.channels,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ChannelNotifier extends Notifier<ChannelState> {
  @override
  ChannelState build() {
    ref.watch(currentOrgIdProvider);
    // Schedule fetch after build
    Future.microtask(fetchChannels);
    return const ChannelState();
  }

  Future<void> fetchChannels() async {
    final workspaceState = ref.read(workspaceProvider);
    final String? orgId = workspaceState.selectedWorkspace?.id;
    if (orgId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    final repository = ref.read(channelRepositoryProvider);
    final result = await repository.fetchChannels(orgId);

    if (result is Success<List<Channel>>) {
      final authState = ref.read(authNotifierProvider);
      final userId = authState.user?.id ?? '';
      
      var channelsList = result.value;
      
      try {
        final storage = locator<SecureStorageService>();
        final orderJson = await storage.readData('channel_order_${userId}_$orgId');
        if (orderJson != null && orderJson.isNotEmpty) {
          final List<dynamic> orderedIds = jsonDecode(orderJson) as List<dynamic>;
          final idToIndex = {for (int i = 0; i < orderedIds.length; i++) orderedIds[i].toString(): i};
          
          channelsList = List<Channel>.from(channelsList)..sort((a, b) {
            final idxA = idToIndex[a.id];
            final idxB = idToIndex[b.id];
            if (idxA != null && idxB != null) return idxA.compareTo(idxB);
            if (idxA != null) return -1;
            if (idxB != null) return 1;
            return a.name.compareTo(b.name);
          });
        }
      } catch (_) {}

      state = state.copyWith(isLoading: false, channels: channelsList);
      
      // Auto-update general channel selection from name to UUID
      final activeChat = ref.read(activeChatProvider);
      if (activeChat.type == ActiveChatType.channel && activeChat.id == 'general') {
        final realGeneral = channelsList.firstWhere(
          (c) => c.name == 'general',
          orElse: () => channelsList.isNotEmpty
              ? channelsList.first
              : const Channel(
                  id: 'general',
                  name: 'general',
                  description: '',
                  organisationId: '',
                  ownerId: '',
                ),
        );
        if (realGeneral.id != 'general') {
          ref.read(activeChatProvider.notifier).selectChannel(realGeneral.id);
        }
      }
    } else if (result is Failure<List<Channel>>) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.error.message,
      );
    }
  }

  Future<bool> createChannel({
    required String name,
    required String description,
    required bool isPrivate,
    String? topic,
  }) async {
    final workspaceState = ref.read(workspaceProvider);
    final authState = ref.read(authNotifierProvider);
    final String? orgId = workspaceState.selectedWorkspace?.id;
    final String? username =
        authState.user?.username ?? authState.user?.email.split('@').first;

    if (orgId == null || username == null) return false;

    final repository = ref.read(channelRepositoryProvider);
    final result = await repository.createChannel(
      name: name,
      description: description,
      orgId: orgId,
      username: username,
      isPrivate: isPrivate,
      topic: topic,
    );

    if (result is Success<Channel>) {
      state = state.copyWith(channels: [...state.channels, result.value]);
      return true;
    } else {
      return false;
    }
  }

  Future<bool> updateChannelTopicOrDescription({
    required String channelId,
    String? topic,
    String? description,
  }) async {
    final repository = ref.read(channelRepositoryProvider);
    final result = await repository.updateChannelTopicOrDescription(
      channelId: channelId,
      topic: topic,
      description: description,
    );

    if (result is Success<void>) {
      // Update local state
      final updatedChannels = state.channels.map((c) {
        if (c.id == channelId) {
          return Channel(
            id: c.id,
            name: c.name,
            description: description ?? c.description,
            organisationId: c.organisationId,
            isPrivate: c.isPrivate,
            ownerId: c.ownerId,
            archived: c.archived,
            topic: topic ?? c.topic,
            unreadCount: c.unreadCount,
            membersCount: c.membersCount,
          );
        }
        return c;
      }).toList();
      state = state.copyWith(channels: updatedChannels);
      return true;
    }
    return false;
  }

  Future<bool> archiveChannel(String channelId, bool archived) async {
    final repository = ref.read(channelRepositoryProvider);
    final result = await repository.archiveChannel(channelId, archived);

    if (result is Success<void>) {
      if (archived) {
        state = state.copyWith(
          channels: state.channels.where((c) => c.id != channelId).toList(),
        );
      } else {
        state = state.copyWith(
          channels: state.channels.map((c) {
            if (c.id == channelId) {
              return c.copyWith(archived: archived);
            }
            return c;
          }).toList(),
        );
      }
      return true;
    }
    return false;
  }

  Future<void> reorderChannels(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final channelsList = List<Channel>.from(state.channels);
    final previousList = List<Channel>.from(channelsList);

    final item = channelsList.removeAt(oldIndex);
    channelsList.insert(newIndex, item);
    state = state.copyWith(channels: channelsList);

    final workspaceState = ref.read(workspaceProvider);
    final String? orgId = workspaceState.selectedWorkspace?.id;
    final authState = ref.read(authNotifierProvider);
    final userId = authState.user?.id ?? '';
    
    if (orgId != null && userId.isNotEmpty) {
      final orderedIds = channelsList.map((c) => c.id).toList();
      try {
        final storage = locator<SecureStorageService>();
        await storage.writeData('channel_order_${userId}_$orgId', jsonEncode(orderedIds));
      } catch (_) {}
    }

    final network = ref.read(networkStatusProvider);
    if (network == NetworkStatus.offline) {
      state = state.copyWith(channels: previousList);
      if (orgId != null && userId.isNotEmpty) {
        final orderedIds = previousList.map((c) => c.id).toList();
        try {
          final storage = locator<SecureStorageService>();
          await storage.writeData('channel_order_${userId}_$orgId', jsonEncode(orderedIds));
        } catch (_) {}
      }
      throw Exception('Network connection lost. Reorder reverted.');
    }
  }

  Future<bool> toggleChannelPrivacy(String channelId, bool isPrivate) async {
    final repository = ref.read(channelRepositoryProvider);
    final result = await repository.toggleChannelPrivacy(channelId, isPrivate);
    if (result is Success<void>) {
      state = state.copyWith(
        channels: state.channels.map((c) {
          if (c.id == channelId) {
            return c.copyWith(isPrivate: isPrivate);
          }
          return c;
        }).toList(),
      );
      return true;
    }
    return false;
  }

  Future<bool> leaveChannel(String channelId) async {
    final repository = ref.read(channelRepositoryProvider);
    final result = await repository.leaveChannel(channelId);
    if (result is Success<void>) {
      state = state.copyWith(
        channels: state.channels.where((c) => c.id != channelId).toList(),
      );
      return true;
    }
    return false;
  }

  Future<bool> joinChannel(String channelId) async {
    final repository = ref.read(channelRepositoryProvider);
    final result = await repository.joinChannel(channelId);
    if (result is Success<void>) {
      await fetchChannels();
      return true;
    }
    return false;
  }

  Future<bool> addChannelMembers(String channelId, List<String> userIds) async {
    final repository = ref.read(channelRepositoryProvider);
    final result = await repository.addChannelMembers(channelId, userIds);
    if (result is Success<void>) {
      state = state.copyWith(
        channels: state.channels.map((c) {
          if (c.id == channelId) {
            return c.copyWith(membersCount: c.membersCount + userIds.length);
          }
          return c;
        }).toList(),
      );
      return true;
    }
    return false;
  }
}

final channelProvider = NotifierProvider<ChannelNotifier, ChannelState>(
  ChannelNotifier.new,
);
