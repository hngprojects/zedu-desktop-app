class ChannelMessage {
  const ChannelMessage({
    required this.threadId,
    required this.channelId,
    required this.orgId,
    required this.username,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
    required this.lastReply,
    required this.avatarUrl,
    required this.defaultAvatarUrl,
    required this.userType,
    required this.type,
    required this.messageHtml,
    required this.channelName,
    required this.channelType,
    required this.currentStatus,
    required this.fullName,
    required this.email,
    required this.userId,
    required this.edited,
    required this.isPinned,
    required this.pinnedDetails,
    required this.reactions,
  });

  final String threadId;
  final String channelId;
  final String orgId;
  final String username;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final DateTime? lastReply;
  final String avatarUrl;
  final String defaultAvatarUrl;
  final String userType;
  final String type;
  final String messageHtml;
  final String channelName;
  final String channelType;
  final String currentStatus;
  final String fullName;
  final String email;
  final String userId;
  final bool edited;
  final bool isPinned;
  final Map<String, dynamic> pinnedDetails;
  final dynamic reactions;
}
