import 'package:hive_flutter/hive_flutter.dart';
import 'package:zedu/features/dms/domain/domain.dart';

class DmLocalDatasource {
  static const String boxName = 'dm_conversations';

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<Map>(boxName);
    }
  }

  Future<void> cacheConversations(List<DmConversation> conversations) async {
    final box = Hive.box<Map>(boxName);
    final map = {
      for (var c in conversations)
        c.id: {
          'id': c.id,
          'participant_id': c.participantId,
          'participant_name': c.participantName,
          'participant_avatar_url': c.participantAvatarUrl,
          'last_message': c.lastMessage,
          'last_message_at': c.lastMessageAt.toIso8601String(),
          'unread_count': c.unreadCount,
        }
    };
    await box.putAll(map);
  }

  List<DmConversation> getCachedConversations() {
    if (!Hive.isBoxOpen(boxName)) return [];
    final box = Hive.box<Map>(boxName);
    final conversations = box.values.map((e) {
      return DmConversation.fromJson(Map<String, dynamic>.from(e));
    }).toList();
    conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return conversations;
  }
}
