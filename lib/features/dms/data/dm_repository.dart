import 'package:zedu/core/core.dart';
import 'package:zedu/features/dms/domain/domain.dart';

final dmRepositoryProvider = Provider<DmRepository>((ref) {
  final apiClient = locator<ApiBaseService>();
  return DmRepository(apiClient);
});

class DmRepository {
  static const int pageSize = 50;
  static const String _defaultOrgId = '01910544-d1e1-7ada-bdac-c761e527ec91';

  final ApiBaseService _apiClient;

  DmRepository(this._apiClient);

  Future<List<DmConversation>> getConversations({int page = 1}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      path: '/organizations/$_defaultOrgId/recent-dm',
      queryParameters: {'page': page, 'limit': pageSize},
    );

    final data = response.data;
    final rawList = data['data'];
    final list = (rawList is List ? rawList : const <dynamic>[])
        .map((e) => DmConversation.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  /// Fetches paginated messages for a specific DM channel.
  Future<List<Map<String, dynamic>>> getMessages(
    String channelId, {
    int page = 1,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      path: '/channels/$channelId/messages',
      queryParameters: {'page': page, 'limit': pageSize},
    );

    final data = response.data;
    final rawMessages = data['messages'] ?? data['data'];
    final messages = rawMessages is Map<String, dynamic>
        ? rawMessages['messages'] ?? rawMessages['data']
        : rawMessages;

    if (messages is! List) return const [];

    return messages
        .whereType<Map<dynamic, dynamic>>()
        .map((message) => Map<String, dynamic>.from(message))
        .toList();
  }

  Future<void> sendMessage(
    String channelId,
    String content, {
    List<XFile>? media,
    List<dynamic>? mentions,
  }) async {
    await _apiClient.post<Map<String, dynamic>>(
      path: '/channels/$channelId/messages',
      data: {
        "content": content,
        if (media != null && media.isNotEmpty)
          "media": media.map(_mediaPayloadFromFile).toList(),
        if (mentions != null) "mentions": mentions,
      },
    );
  }

  Map<String, dynamic> _mediaPayloadFromFile(XFile file) {
    return {
      'name': file.name,
      'path': file.path,
      if (file.mimeType != null) 'mime_type': file.mimeType,
    };
  }
}
