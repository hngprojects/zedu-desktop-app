import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ChannelRemoteDataSource {
  ChannelRemoteDataSource({required ApiBaseService apiBaseService})
    : _apiBaseService = apiBaseService;

  final ApiBaseService _apiBaseService;

  Future<List<WorkspaceChannel>> getChannels() async {
    final response = await _apiBaseService.get<Map<String, dynamic>>(
      path: '/channels',
    );

    final payload = response.data;

    final rawChannels = payload['channels'];

    if (rawChannels is List) {
      return rawChannels
          .expand((item) {
            if (item is Map<String, dynamic>) {
              final data = item['data'];
              if (data is List) return data;
            }
            return const [];
          })
          .whereType<Map<String, dynamic>>()
          .map(WorkspaceChannel.fromJson)
          .toList();
    }

    final data = payload['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(WorkspaceChannel.fromJson)
          .toList();
    }

    return const [];
  }

  Future<WorkspaceChannel> createChannel({
    required String name,
    required String organisationId,
    required String username,
    required bool isPrivate,
    required String topic,
    String description = '',
  }) async {
    final response = await _apiBaseService.post<Map<String, dynamic>>(
      path: '/channels',
      data: {
        'name': name,
        'description': description,
        'organisation_id': organisationId,
        'username': username,
        'is_private': isPrivate,
        'topic': topic,
      },
    );

    final data = response.data['data'];

    if (data is Map<String, dynamic>) {
      return WorkspaceChannel.fromJson(data);
    }

    return WorkspaceChannel(
      name: name,
      visibility: isPrivate
          ? ChannelVisibility.private
          : ChannelVisibility.public,
      category: ChannelCategory.general,
      topic: topic,
      description: description,
    );
  }

  Future<void> updateChannel({
    required String channelId,
    required String name,
    required String description,
    required String topic,
  }) async {
    await _apiBaseService.patch<Map<String, dynamic>>(
      path: '/channels/$channelId',
      data: {'name': name, 'description': description, 'topic': topic},
    );
  }
}
