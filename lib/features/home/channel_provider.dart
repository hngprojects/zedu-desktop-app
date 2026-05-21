import 'package:zedu/core/core.dart';

import 'channel_model.dart';
import 'data/channel_remote_datasource.dart';

final channelProvider =
    NotifierProvider<ChannelNotifier, List<WorkspaceChannel>>(
      ChannelNotifier.new,
    );

class ChannelNotifier extends Notifier<List<WorkspaceChannel>> {
  late final ChannelRemoteDataSource _remoteDataSource;

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
      state = state
          .where(
            (channel) =>
                channel.name.toLowerCase() != name.trim().toLowerCase(),
          )
          .toList();

      return error.friendlyMessage;
    } catch (_) {
      state = state
          .where(
            (channel) =>
                channel.name.toLowerCase() != name.trim().toLowerCase(),
          )
          .toList();

      return 'Unable to create channel. Please try again.';
    }
  }

  String _topicFromCategory(ChannelCategory category) {
    return switch (category) {
      ChannelCategory.general => 'General',
      ChannelCategory.classGroup => 'Class',
      ChannelCategory.team => 'Team',
    };
  }
}
