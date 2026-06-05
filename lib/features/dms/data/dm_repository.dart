import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final dmRepositoryProvider = Provider<DmRepository>((ref) {
  final apiClient = locator<ApiBaseService>();
  return DmRepository(apiClient);
});

class DmRepository {
  static const int pageSize = 20;

  final ApiBaseService _apiClient;

  DmRepository(this._apiClient);

  Future<List<DmConversation>> getConversations({
    required String orgId,
    int page = 1,
    bool recentDm = false,
    String? search,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      path: '/organisations/$orgId/dms',
      queryParameters: {
        'page': page,
        'limit': pageSize,
        'recent_dm': recentDm,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final data = response.data;
    final rawList = data['data'];
    final list = (rawList is List ? rawList : const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(DmConversation.fromJson)
        .toList();

    list.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));

    return list;
  }

  Future<List<Map<String, dynamic>>> getMessages(
    String channelId, {
    int page = 1,
    String? threadId,
    String channelType = 'channel', // 'channel', 'dm', or 'group_dm'
  }) async {
    String endpointPath;
    if (threadId != null && threadId.isNotEmpty) {
      if (channelType == 'dm') {
        endpointPath = '/dms/thread/$threadId/channels/$channelId';
      } else if (channelType == 'group_dm') {
        endpointPath = '/group-dms/thread/$threadId/channels/$channelId';
      } else {
        endpointPath = '/threads/$threadId/channels/$channelId';
      }
    } else {
      if (channelType == 'dm') {
        endpointPath = '/dms/messages/$channelId';
      } else if (channelType == 'group_dm') {
        endpointPath = '/group-dms/messages/$channelId';
      } else {
        endpointPath = '/channels/$channelId/messages';
      }
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      path: endpointPath,
      queryParameters: {'page': page, 'limit': pageSize},
    );

    final data = response.data;
    final rawMessages = data['messages'] ?? data['data'];
    final messages = rawMessages is Map<String, dynamic>
        ? rawMessages['messages'] ?? rawMessages['data']
        : rawMessages;

    if (messages is! List) return const [];

    var parsedMessages = messages
        .whereType<Map<dynamic, dynamic>>()
        .map((message) => Map<String, dynamic>.from(message))
        .toList();

    if (threadId != null && threadId.isNotEmpty) {
      parsedMessages = parsedMessages.where((m) {
        final mThreadId = m['thread_id']?.toString() ?? '';
        final mId = m['id']?.toString() ?? '';
        return mThreadId == threadId || mId == threadId;
      }).toList();
    }

    return parsedMessages;
  }

  Future<Map<String, dynamic>> sendMessage(
    String channelId,
    String content, {
    String? orgId,
    String? threadId,
    List<XFile>? media,
    List<dynamic>? mentions,
    String channelType = 'channel', // 'channel', 'dm', or 'group_dm'
  }) async {
    final bool isThreadReply = threadId != null && threadId.isNotEmpty;
    String path = '';
    Map<String, dynamic> data = {"content": content};

    if (media != null && media.isNotEmpty) {
      data["media"] = media.map(_mediaPayloadFromFile).toList();
    }

    if (channelType == 'group_dm') {
      if (isThreadReply) {
        path = '/group-dms/messages/$channelId';
        data["thread_id"] = threadId;
      } else {
        path = '/group-dms/channels/$channelId/threads';
      }
    } else if (channelType == 'dm') {
      if (isThreadReply) {
        path = '/dms/messages/$channelId';
        data["thread_id"] = threadId;
      } else {
        path = '/dms/channels/$channelId/threads';
      }
      if (mentions != null && mentions.isNotEmpty) data['mentions'] = mentions;
    } else {
      // Default channel handling
      if (isThreadReply) {
        path = '/channels/$channelId/messages';
        data["thread_id"] = threadId;
      } else {
        path = '/threads/$channelId';
      }
      if (mentions != null && mentions.isNotEmpty) data['mentions'] = mentions;
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      path: path,
      data: data,
    );

    final responseData = response.data['data'];
    if (responseData is List && responseData.isNotEmpty) {
      return (responseData.first as Map<dynamic, dynamic>)
          .cast<String, dynamic>();
    } else if (responseData is Map) {
      return responseData.cast<String, dynamic>();
    }
    return const {};
  }

  String _generateUuid() {
    final random = Random.secure();
    final chars = '0123456789abcdef';
    final buffer = StringBuffer();
    for (int i = 0; i < 36; i++) {
      if (i == 8 || i == 13 || i == 18 || i == 23) {
        buffer.write('-');
      } else if (i == 14) {
        buffer.write('4');
      } else if (i == 19) {
        buffer.write(chars[random.nextInt(4) + 8]);
      } else {
        buffer.write(chars[random.nextInt(16)]);
      }
    }
    return buffer.toString();
  }

  Map<String, dynamic> _mediaPayloadFromFile(XFile file) {
    final bool isUrl =
        file.path.startsWith('http://') || file.path.startsWith('https://');
    final String serverPath = isUrl
        ? file.path
        : '${dotenv.maybeGet('MOCK_UPLOADS_URL') ?? ''}${file.name}';
    return {
      'id': _generateUuid(),
      'name': file.name,
      'file_name': file.name,
      'path': serverPath,
      'file_link': serverPath,
      'file_type': file.name.split('.').last,
      if (file.mimeType != null) 'mime_type': file.mimeType,
    };
  }

  Future<void> editMessage(
    String channelId, {
    required String content,
    String? threadId,
    List<Map<String, dynamic>>? media,
    List<Map<String, dynamic>>? mentions,
  }) async {
    await _apiClient.put<Map<String, dynamic>>(
      path: '/dms/messages/$channelId',
      data: {
        'content': content,
        ...?(threadId != null ? {'thread_id': threadId} : null),
        ...?(media != null ? {'media': media} : null),
        ...?(mentions != null ? {'mentions': mentions} : null),
      },
    );
  }

  Future<void> deleteMessage(String channelId, String messageId) async {
    await _apiClient.delete<Map<String, dynamic>>(
      path: '/channels/$channelId/messages/$messageId',
    );
  }

  Future<Map<String, dynamic>> addGroupDmParticipants(
    String channelId,
    List<String> userIds,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      path: '/organisations/group-dms/$channelId/participants',
      data: {'user_ids': userIds},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createDmRoom({
    required String orgId,
    required String participantId,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      path: '/organisations/$orgId/dms',
      data: {'chat_type': 'user', 'participant_id': participantId},
    );
    return (response.data['data'] as Map<dynamic, dynamic>?)
            ?.cast<String, dynamic>() ??
        const {};
  }
}
