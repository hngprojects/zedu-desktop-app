import 'package:zedu/core/core.dart';

import 'channel_model.dart';
import 'data/channel_remote_datasource.dart';

final channelProvider =
    NotifierProvider<ChannelNotifier, List<WorkspaceChannel>>(
      ChannelNotifier.new,
    );

class ChannelNotifier extends Notifier<List<WorkspaceChannel>> {
  late final ChannelRemoteDataSource _remoteDataSource;
  WorkspaceChannel? selectedChannel;

  void selectChannel(WorkspaceChannel channel) {
    selectedChannel = channel;
    state = [...state];
  }

  @override
  List<WorkspaceChannel> build() {
    _remoteDataSource = ChannelRemoteDataSource(
      apiBaseService: locator<ApiBaseService>(),
    );

    return const [
      WorkspaceChannel(
        name: 'general',
        visibility: ChannelVisibility.public,
        category: ChannelCategory.general,
      ),
    ];
  }

  String? createChannel({
    required String name,
    required ChannelVisibility visibility,
    required ChannelCategory category,
  }) {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return 'Channel name is required';
    }

    final normalizedName = trimmedName.toLowerCase();

    final alreadyExists = state.any(
      (channel) => channel.name.toLowerCase() == normalizedName,
    );

    if (alreadyExists) {
      return 'A channel with this name already exists';
    }

    state = [
      WorkspaceChannel(
        name: trimmedName,
        visibility: visibility,
        category: category,
      ),
      ...state,
    ];

    return null;
  }

  Future<String?> createChannelRemote({
    required String name,
    required ChannelVisibility visibility,
    required ChannelCategory category,
    required String organisationId,
    required String username,
  }) async {
    final localValidationError = createChannel(
      name: name,
      visibility: visibility,
      category: category,
    );

    if (localValidationError != null) {
      return localValidationError;
    }

    try {
      await _remoteDataSource.createChannel(
        name: name.trim(),
        organisationId: organisationId,
        username: username,
        isPrivate: visibility == ChannelVisibility.private,
        topic: _topicFromCategory(category),
        description: _topicFromCategory(category),
      );

      return null;
    } on ApiFailure catch (error) {
      _removeOptimisticChannel(name);
      return error.friendlyMessage;
    } catch (_) {
      _removeOptimisticChannel(name);
      return 'Unable to create channel. Please try again.';
    }
  }

  String? updateChannel({
  required WorkspaceChannel channel,
  required String name,
  required String description,
  required String topic,
}) {
  final trimmedName = name.trim();
  final trimmedDescription = description.trim();
  final trimmedTopic = topic.trim();

  if (trimmedName.isEmpty) {
    return 'Channel name is required';
  }

  final duplicateExists = state.any((existingChannel) {
    final sameName =
        existingChannel.name.toLowerCase() == trimmedName.toLowerCase();

    final sameChannel = _isSameChannel(existingChannel, channel);

    return sameName && !sameChannel;
  });

  if (duplicateExists) {
    return 'A channel with this name already exists';
  }

  final hasNoChanges =
      channel.name == trimmedName &&
      channel.description == trimmedDescription &&
      channel.topic == trimmedTopic;

  if (hasNoChanges) {
    return null;
  }

  WorkspaceChannel? updatedChannel;

  state = state.map((existingChannel) {
    if (_isSameChannel(existingChannel, channel)) {
      updatedChannel = existingChannel.copyWith(
        name: trimmedName,
        description: trimmedDescription,
        topic: trimmedTopic,
      );

      return updatedChannel!;
    }

    return existingChannel;
  }).toList();

  if (updatedChannel != null &&
      selectedChannel != null &&
      _isSameChannel(selectedChannel!, channel)) {
    selectedChannel = updatedChannel;
  }

  return null;
}

  Future<String?> updateChannelRemote({
    required WorkspaceChannel channel,
    required String name,
    required String description,
    required String topic,
  }) async {
    final previousState = state;

    final localValidationError = updateChannel(
      channel: channel,
      name: name,
      description: description,
      topic: topic,
    );

    if (localValidationError != null) {
      return localValidationError;
    }

    final trimmedName = name.trim();
    final trimmedDescription = description.trim();
    final trimmedTopic = topic.trim();

    final hasNoChanges =
        channel.name == trimmedName &&
        channel.description == trimmedDescription &&
        channel.topic == trimmedTopic;

    if (hasNoChanges) {
      return null;
    }

    if (channel.id == null) {
      return null;
    }

    try {
      await _remoteDataSource.updateChannel(
        channelId: channel.id!,
        name: trimmedName,
        description: trimmedDescription,
        topic: trimmedTopic,
      );
      state = state.map((c) {
  if (c.id == channel.id) {
    return WorkspaceChannel(
      id: c.id,
      name: name,
      description: description,
      topic: topic,
      visibility: c.visibility,
      category: c.category,
      membersCount: c.membersCount,
    );
  }
  return c;
}).toList();
      return null;
      
    } on ApiFailure catch (error) {
      state = previousState;
      return error.friendlyMessage;
    } catch (_) {
      state = previousState;
      return 'Unable to update channel. Please try again.';
    }
  }

  void _removeOptimisticChannel(String name) {
    state = state
        .where(
          (channel) => channel.name.toLowerCase() != name.trim().toLowerCase(),
        )
        .toList();
  }

  bool _isSameChannel(WorkspaceChannel first, WorkspaceChannel second) {
    if (first.id != null && second.id != null) {
      return first.id == second.id;
    }

    return first.name.toLowerCase() == second.name.toLowerCase();
  }

  String _topicFromCategory(ChannelCategory category) {
    return switch (category) {
      ChannelCategory.general => 'General',
      ChannelCategory.classGroup => 'Class',
      ChannelCategory.team => 'Team',
    };
  }
}
