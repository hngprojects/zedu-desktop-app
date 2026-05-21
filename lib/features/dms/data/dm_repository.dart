import 'package:zedu/core/core.dart';
import 'package:zedu/features/dms/domain/domain.dart';

final dmRepositoryProvider = Provider<DmRepository>((ref) {
  final apiClient = locator<ApiBaseService>();
  return DmRepository(apiClient);
});

class DmRepository {
  static const int pageSize = 20;

  final ApiBaseService _apiClient;

  DmRepository(this._apiClient);

  /// Fetches paginated DM conversations for the given [orgId].
  ///
  /// Uses `GET /organisations/{org_id}/dms` with pagination and optional
  /// [recentDm] / [search] filters. Results are sorted client-side by
  /// most-recent activity to guarantee AC-1 ordering regardless of backend.
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

    // Client-side sort: most recent activity first (AC-1 guarantee).
    list.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));

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
