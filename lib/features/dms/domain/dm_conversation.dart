import 'package:zedu/core/core.dart';

class DmConversation {
  final String id; // maps to channels_id
  final String participantId; // maps to user_id
  final String participantName; // maps to username
  final String? participantAvatarUrl; // maps to avatar_url or default_avatar_url
  final String lastMessage; // maps to message
  final DateTime lastMessageAt; // maps to created_at
  final int unreadCount; // Defaults to 0 since backend doesn't provide it yet

  DmConversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantAvatarUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory DmConversation.fromJson(Map<String, dynamic> json) {
    return DmConversation(
      id: json['channels_id'] as String? ?? '',
      participantId: json['user_id'] as String? ?? '',
      participantName: json['username'] as String? ?? 'Unknown',
      participantAvatarUrl: json['avatar_url']?.toString().isNotEmpty == true 
          ? json['avatar_url'] as String 
          : json['default_avatar_url'] as String?,
      lastMessage: json['message'] as String? ?? '',
      lastMessageAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String).toLocal() 
          : DateTime.now(),
      unreadCount: 0,
    );
  }
}
