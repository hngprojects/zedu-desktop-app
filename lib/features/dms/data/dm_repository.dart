import 'package:zedu/core/core.dart';
import 'package:zedu/features/dms/domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dmRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DmRepository(apiClient);
});

class DmRepository {
  static const int pageSize = 50;
  // TODO: Replace with dynamic organization ID from auth/workspace provider
  static const String _defaultOrgId = '01910544-d1e1-7ada-bdac-c761e527ec91';

  final ApiBaseService _apiClient;

  DmRepository(this._apiClient);

  Future<List<DmConversation>> getConversations({int page = 1}) async {
    final response = await _apiClient.get(
      path: '/organizations/$_defaultOrgId/recent-dm',
      queryParameters: {'page': page, 'limit': pageSize},
    );
    
    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List)
        .map((e) => DmConversation.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  /// Fetches paginated messages for a specific DM channel.
  Future<List<dynamic>> getMessages(String channelId, {int page = 1}) async {
  Future<List<dynamic>> getMessages(String channelId, {int page = 1}) async {
    final response = await _apiClient.get(
      path: '/channels/$channelId/messages',
      queryParameters: {'page': page, 'limit': pageSize},
    );
    
    final data = response.data as Map<String, dynamic>;
    return data['messages'] as List;
  }

  Future<void> sendMessage(String channelId, String content, {List<dynamic>? media, List<dynamic>? mentions}) async {
    await _apiClient.post(
      path: '/channels/$channelId/messages',
      data: {
        "content": content,
        if (media != null) "media": media,
        if (mentions != null) "mentions": mentions,
      },
    );
  }
}
