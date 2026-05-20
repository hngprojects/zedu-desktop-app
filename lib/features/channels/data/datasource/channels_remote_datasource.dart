import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

abstract interface class ChannelsRemoteDataSource {
  Future<PaginatedChannelMessagesModel> fetchChannelMessages({
    required String channelId,
    int page = 1,
    int limit = 20,
  });

  Future<ChannelMessageModel> sendChannelMessage({
    required String channelId,
    required String contentHtml,
    String? threadId,
    List<ChannelMedia> media = const [],
    List<ChannelMention> mentions = const [],
  });
}

class ChannelsRemoteDataSourceImpl implements ChannelsRemoteDataSource {
  const ChannelsRemoteDataSourceImpl({
    required AppConfig config,
    required ApiBaseService apiBaseService,
  }) : _config = config,
       _apiBaseService = apiBaseService;

  final AppConfig _config;
  final ApiBaseService _apiBaseService;

  static const _tag = 'ChannelsRemoteDataSource';

  static int _mockMessageCounter = 4;

  static final Map<String, List<Map<String, dynamic>>> _mockMessagesByChannel = {
    ChannelsDevDefaults.mockChannelId: [
      {
        'thread_id': '019e4600-fe1a-78cf-a7df-3aafe1b7db4f',
        'channels_id': ChannelsDevDefaults.mockChannelId,
        'org_id': ChannelsDevDefaults.mockOrgId,
        'username': 'alameen',
        'status': 'success',
        'created_at': '2026-05-20T15:28:50.715175123Z',
        'updated_at': '2026-05-20T15:28:50.715175123Z',
        'message_count': 0,
        'last_reply': '0001-01-01T00:00:00Z',
        'avatar_url':
            'https://lh3.googleusercontent.com/a/ACg8ocIIcIQtbWu7auTV4TuPj0oXOW5tr3W2CHZaDSUkwFPEuInchg=s96-c',
        'default_avatar_url':
            'https://media.zedu.chat/telexstagingbucket/public/default_avatars/default_avatar_21.png',
        'user_type': 'user',
        'type': 'message',
        'message': '<p><strong>Welcome</strong> to <em>#general</em>.</p>',
        'channel_name': 'general',
        'channel_type': 'public',
        'current_status': 'pending',
        'full_name': 'alameen',
        'email': 'alameensad6@gmail.com',
        'user_id': '019e458c-6ea4-78c9-b631-2f19a62d30b2',
        'edited': false,
        'is_pinned': false,
        'pinned_details': <String, dynamic>{},
        'reactions': null,
      },
      {
        'thread_id': '019e4600-fe1a-78cf-a7df-3aafe1b7db4f-2',
        'channels_id': ChannelsDevDefaults.mockChannelId,
        'org_id': ChannelsDevDefaults.mockOrgId,
        'username': 'jane',
        'status': 'success',
        'created_at': '2026-05-20T14:20:00.715175123Z',
        'updated_at': '2026-05-20T14:20:00.715175123Z',
        'message_count': 0,
        'last_reply': '0001-01-01T00:00:00Z',
        'avatar_url': '',
        'default_avatar_url':
            'https://media.zedu.chat/telexstagingbucket/public/default_avatars/default_avatar_17.png',
        'user_type': 'user',
        'type': 'message',
        'message': '<p>Drafts are ready for review.</p>',
        'channel_name': 'general',
        'channel_type': 'public',
        'current_status': 'pending',
        'full_name': 'Jane Doe',
        'email': 'jane@example.com',
        'user_id': '019e458c-6ea4-78c9-b631-2f19a62d3001',
        'edited': false,
        'is_pinned': false,
        'pinned_details': <String, dynamic>{},
        'reactions': null,
      },
      {
        'thread_id': '019e4600-fe1a-78cf-a7df-3aafe1b7db4f-3',
        'channels_id': ChannelsDevDefaults.mockChannelId,
        'org_id': ChannelsDevDefaults.mockOrgId,
        'username': 'bot-ops',
        'status': 'success',
        'created_at': '2026-05-20T13:10:00.715175123Z',
        'updated_at': '2026-05-20T13:10:00.715175123Z',
        'message_count': 0,
        'last_reply': '0001-01-01T00:00:00Z',
        'avatar_url': '',
        'default_avatar_url':
            'https://media.zedu.chat/telexstagingbucket/public/default_avatars/default_avatar_8.png',
        'user_type': 'bot',
        'type': 'message',
        'message': '<p><code>deploy</code> finished successfully.</p>',
        'channel_name': 'general',
        'channel_type': 'public',
        'current_status': 'pending',
        'full_name': 'Ops Bot',
        'email': 'ops-bot@example.com',
        'user_id': '019e458c-6ea4-78c9-b631-2f19a62d3002',
        'edited': false,
        'is_pinned': false,
        'pinned_details': <String, dynamic>{},
        'reactions': null,
      },
    ],
  };

  @override
  Future<PaginatedChannelMessagesModel> fetchChannelMessages({
    required String channelId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      if (_config.usesMockData) {
        AppLogger.d('Using mock data for GET /threads/channels/$channelId', tag: _tag);
        await Future<void>.delayed(const Duration(milliseconds: 280));
        return _mockFetch(channelId: channelId, page: page, limit: limit);
      }

      final response = await _apiBaseService.get<Map<String, dynamic>>(
        path: 'threads/channels/$channelId',
        queryParameters: {'page': page, 'limit': limit},
      );

      return PaginatedChannelMessagesModel.fromJson(response.data);
    } on ApiFailure {
      rethrow;
    } catch (error) {
      AppLogger.e('Failed to fetch channel messages', tag: _tag, error: error);
      throw ApiFailure.fromParsingError(error, path: 'threads/channels/$channelId');
    }
  }

  @override
  Future<ChannelMessageModel> sendChannelMessage({
    required String channelId,
    required String contentHtml,
    String? threadId,
    List<ChannelMedia> media = const [],
    List<ChannelMention> mentions = const [],
  }) async {
    try {
      if (_config.usesMockData) {
        AppLogger.d('Using mock data for POST /threads/$channelId', tag: _tag);
        await Future<void>.delayed(const Duration(milliseconds: 220));
        return _mockSend(
          channelId: channelId,
          contentHtml: contentHtml,
          threadId: threadId,
        );
      }

      final response = await _apiBaseService.post<Map<String, dynamic>>(
        path: 'threads/$channelId',
        data: {
          'content': contentHtml,
          if (threadId != null && threadId.isNotEmpty) 'thread_id': threadId,
          if (media.isNotEmpty) 'media': media.map((m) => m.toJson()).toList(),
          if (mentions.isNotEmpty)
            'mentions': mentions.map((m) => m.toJson()).toList(),
        },
      );

      final payload = response.data['data'] as Map<String, dynamic>;
      return ChannelMessageModel.fromJson(payload);
    } on ApiFailure {
      rethrow;
    } catch (error) {
      AppLogger.e('Failed to send channel message', tag: _tag, error: error);
      throw ApiFailure.fromParsingError(error, path: 'threads/$channelId');
    }
  }

  PaginatedChannelMessagesModel _mockFetch({
    required String channelId,
    required int page,
    required int limit,
  }) {
    final messages = _mockMessagesByChannel[channelId] ?? const <Map<String, dynamic>>[];
    final offset = (page - 1) * limit;
    final chunk = offset >= messages.length
        ? const <Map<String, dynamic>>[]
        : messages.skip(offset).take(limit).toList();

    final totalPages = messages.isEmpty ? 1 : (messages.length / limit).ceil();

    return PaginatedChannelMessagesModel.fromJson({
      'data': chunk,
      'pagination': {
        'current_page': page,
        'page_count': chunk.length,
        'total_pages_count': totalPages,
      },
    });
  }

  ChannelMessageModel _mockSend({
    required String channelId,
    required String contentHtml,
    required String? threadId,
  }) {
    final now = DateTime.now().toUtc();
    _mockMessageCounter += 1;
    final generatedThreadId = threadId?.trim().isNotEmpty == true
        ? threadId!.trim()
        : 'mock-thread-${now.millisecondsSinceEpoch}-$_mockMessageCounter';

    final payload = <String, dynamic>{
      'thread_id': generatedThreadId,
      'channels_id': channelId,
      'org_id': ChannelsDevDefaults.mockOrgId,
      'username': 'alameen',
      'status': 'success',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'message_count': 0,
      'last_reply': '0001-01-01T00:00:00Z',
      'avatar_url':
          'https://lh3.googleusercontent.com/a/ACg8ocIIcIQtbWu7auTV4TuPj0oXOW5tr3W2CHZaDSUkwFPEuInchg=s96-c',
      'default_avatar_url':
          'https://media.zedu.chat/telexstagingbucket/public/default_avatars/default_avatar_21.png',
      'user_type': 'user',
      'type': 'message',
      'message': contentHtml,
      'channel_name': 'general',
      'channel_type': 'public',
      'current_status': 'pending',
      'full_name': 'alameen',
      'email': 'alameensad6@gmail.com',
      'user_id': '019e458c-6ea4-78c9-b631-2f19a62d30b2',
      'edited': false,
      'is_pinned': false,
      'pinned_details': <String, dynamic>{},
      'reactions': null,
    };

    final current = _mockMessagesByChannel[channelId] ?? <Map<String, dynamic>>[];
    _mockMessagesByChannel[channelId] = [payload, ...current];

    return ChannelMessageModel.fromJson(payload);
  }
}
