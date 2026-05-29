import 'dart:math' as math;
import 'package:zedu/core/core.dart';

import '../domain/dm_conversation.dart';

final dmRepositoryProvider = Provider<DmRepository>((ref) {
  final apiClient = locator<ApiBaseService>();
  return DmRepository(apiClient);
});

class DmRepository {
  static const int pageSize = 20;

  final ApiBaseService _apiClient;

  DmRepository(this._apiClient);

  static bool isValidChannelId(String channelId) {
    return channelId.isNotEmpty;
  }

  Future<List<DmConversation>> getConversations({
    required String orgId,
    int page = 1,
    bool recentDm = false,
    String? search,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      path: ApiEndpoints.organizationDms(orgId),
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

  /// Creates a new DM channel with the given [userId] inside [orgId].
  /// Returns the [DmConversation] with the real server-assigned channelId.
  Future<DmConversation> createDmChannel({
    required String orgId,
    required String userId,
  }) async {
    // Generate a UUID v4 to satisfy the backend's required channel_id field.
    final random = math.Random();
    const hexDigits = '0123456789abcdef';
    String randomHex(int length) {
      return List.generate(length, (_) => hexDigits[random.nextInt(16)]).join();
    }

    final generatedChannelId =
        '${randomHex(8)}-${randomHex(4)}-4${randomHex(3)}-a${randomHex(3)}-${randomHex(12)}';

    final response = await _apiClient.post<Map<String, dynamic>>(
      path: ApiEndpoints.organizationDms(orgId),
      data: {
        'participant_id': userId,
        'chat_type': 'user',
        'channel_id': generatedChannelId,
      },
    );

    final data = response.data;
    // The API may nest the result under 'data' or return it flat.
    final payload = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;

    AppLogger.d('createDmChannel payload: $payload', tag: 'DmRepository');

    final conv = DmConversation.fromJson(payload);

    AppLogger.d(
      'createDmChannel returned channelId: "${conv.channelId}"',
      tag: 'DmRepository',
    );

    // Fallback: if the server response did not map to a valid channelId,
    // use the generated one we sent so the conversation is immediately usable.
    if (!isValidChannelId(conv.channelId)) {
      AppLogger.w(
        'Server returned no valid channelId — falling back to generated: "$generatedChannelId"',
        tag: 'DmRepository',
      );
      return conv.copyWith(channelId: generatedChannelId);
    }

    return conv;
  }

  Future<List<Map<String, dynamic>>> getMessages(
    String channelId, {
    int page = 1,
  }) async {
    if (!isValidChannelId(channelId)) return const [];

    AppLogger.d(
      'Fetching messages for channel: $channelId (page: $page)',
      tag: 'DmRepository',
    );
    final response = await _apiClient.get<Map<String, dynamic>>(
      path: ApiEndpoints.dmsMessages(channelId),
      queryParameters: {'page': page, 'limit': pageSize},
    );

    AppLogger.d(
      'getMessages response status: ${response.statusCode}',
      tag: 'DmRepository',
    );

    final data = response.data;
    final rawMessages = data['messages'] ?? data['data'];
    AppLogger.d(
      'Raw messages payload for $channelId: ${rawMessages.runtimeType}',
      tag: 'DmRepository',
    );
    final messages = rawMessages is Map<String, dynamic>
        ? rawMessages['messages'] ?? rawMessages['data']
        : rawMessages;

    if (messages is! List) return const [];

    final parsed = messages
        .whereType<Map<dynamic, dynamic>>()
        .map((message) => Map<String, dynamic>.from(message))
        .toList();

    // Normalize field names from thread-format to message-format
    for (final m in parsed) {
      // Normalize 'thread_id' → 'id' so the UI has a consistent key
      if ((!m.containsKey('id') || (m['id']?.toString() ?? '').isEmpty) &&
          m.containsKey('thread_id')) {
        m['id'] = m['thread_id'];
      }
      // Some responses use 'message' for the body instead of 'content'
      final currentContent = m['content']?.toString() ?? '';
      if (currentContent.isEmpty &&
          m.containsKey('message') &&
          m['message'] is String &&
          (m['message'] as String).isNotEmpty) {
        m['content'] = m['message'];
      }
      // Normalize timestamp keys
      if (!m.containsKey('created_at') && m.containsKey('createdAt')) {
        m['created_at'] = m['createdAt'];
      }
      // Normalize sender id keys
      if (!m.containsKey('user_id') && m.containsKey('userId')) {
        m['user_id'] = m['userId'];
      }
    }

    // Log timestamps for a quick sanity check (first few messages only)
    try {
      final sample = parsed
          .take(5)
          .map((m) => m['created_at'] ?? m['createdAt'] ?? m['timestamp'])
          .toList();
      AppLogger.d(
        'Message timestamps sample for $channelId: $sample',
        tag: 'DmRepository',
      );
    } catch (_) {}

    return parsed;
  }

  Future<Map<String, dynamic>?> sendMessage(
    String channelId,
    String content, {
    List<Map<String, dynamic>>? media,
    List<dynamic>? mentions,
  }) async {
    if (!isValidChannelId(channelId)) {
      throw const ApiFailure(
        message:
            'Cannot send message: DM channel has not been created yet. '
            'Please wait for the conversation to be established.',
        kind: ApiFailureKind.client,
      );
    }
    final payload = {
      'content': content,
      'media': media ?? <Map<String, dynamic>>[],
      'mentions': mentions ?? <dynamic>[],
    };

    AppLogger.d(
      'Sending message to $channelId payload: $payload',
      tag: 'DmRepository',
    );
    final response = await _apiClient.post<Map<String, dynamic>>(
      path: ApiEndpoints.dmsMessages(channelId),
      data: payload,
    );

    AppLogger.d(
      'sendMessage response status: ${response.statusCode}',
      tag: 'DmRepository',
    );
    try {
      AppLogger.d(
        'sendMessage response data: ${response.data}',
        tag: 'DmRepository',
      );
    } catch (_) {}

    // Try to extract the created message from the response if present.
    final respData = response.data;
    // Some APIs return the created resource under 'data' or 'message'.
    final responseData = respData['data'] ?? respData['message'] ?? respData;
    if (responseData is Map<String, dynamic>) {
      return Map<String, dynamic>.from(responseData);
    }
    return null;
  }

  Future<void> editMessage(
    String channelId, {
    required String content,
    List<Map<String, dynamic>>? media,
    List<Map<String, dynamic>>? mentions,
  }) async {
    if (!isValidChannelId(channelId)) {
      throw const ApiFailure(
        message: 'Cannot edit message: DM channel has not been created yet.',
        kind: ApiFailureKind.client,
      );
    }

    await _apiClient.put<Map<String, dynamic>>(
      path: ApiEndpoints.dmsMessages(channelId),
      data: {
        'content': content,
        'media': media ?? <Map<String, dynamic>>[],
        'mentions': mentions ?? <Map<String, dynamic>>[],
      },
    );
  }
}
