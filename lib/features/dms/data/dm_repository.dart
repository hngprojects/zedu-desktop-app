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

  /// Fetches a paginated list of DM conversations.
  /// [page] is 1-indexed. Results are sorted by most recent message.
  Future<List<DmConversation>> getConversations({int page = 1}) async {
    try {
      final response = await _apiClient.get(
        path: '/organizations/$_defaultOrgId/recent-dm',
        queryParameters: {'page': page, 'limit': pageSize},
      );
      
      final data = response.data as Map<String, dynamic>;
      final list = (data['data'] as List)
          .map((e) => DmConversation.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      // Fallback to mock data on network error to ensure UI displays during development
      return _getMockConversations();
    }
  }

  /// Fetches paginated messages for a specific DM channel.
  Future<List<dynamic>> getMessages(String channelId, {int page = 1}) async {
    try {
      final response = await _apiClient.get(
        path: '/channels/$channelId/messages',
        queryParameters: {'page': page, 'limit': pageSize},
      );
      
      final data = response.data as Map<String, dynamic>;
      return data['messages'] as List;
    } catch (e) {
      return [];
    }
  }

  /// Sends a direct message.
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

  Future<List<DmConversation>> _getMockConversations() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      DmConversation(
        id: '1',
        participantId: 'p1',
        participantName: 'Steven James',
        participantAvatarUrl: null,
        lastMessage: 'You: Will be back soon sha',
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 5)),
        unreadCount: 0,
      ),
      DmConversation(
        id: '2',
        participantId: 'p2',
        participantName: 'Devon Lane',
        participantAvatarUrl: null,
        lastMessage: 'You: Can we get on a buzz?',
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 45)),
        unreadCount: 0,
      ),
      DmConversation(
        id: '3',
        participantId: 'p3',
        participantName: 'Bewaji Wright',
        participantAvatarUrl: null,
        lastMessage: 'Yes everyone can copy without me having to give edit access',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
        unreadCount: 1,
      ),
      DmConversation(
        id: '4',
        participantId: 'p4',
        participantName: 'Jenny Wilson',
        participantAvatarUrl: null,
        lastMessage: 'Okay thank you',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 4)),
        unreadCount: 0,
      ),
    ];
  }
}
