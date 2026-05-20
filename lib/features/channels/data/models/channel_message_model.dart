import 'package:zedu/features/features.dart';

class ChannelMessageModel {
  const ChannelMessageModel({
    required this.threadId,
    required this.channelsId,
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
    required this.message,
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
  final String channelsId;
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
  final String message;
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

  factory ChannelMessageModel.fromJson(Map<String, dynamic> json) {
    return ChannelMessageModel(
      threadId: json['thread_id'] as String? ?? '',
      channelsId: json['channels_id'] as String? ?? '',
      orgId: json['org_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: _parseDate(json['created_at']) ?? DateTime.now().toUtc(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now().toUtc(),
      messageCount: json['message_count'] as int? ?? 0,
      lastReply: _parseDate(json['last_reply']),
      avatarUrl: json['avatar_url'] as String? ?? '',
      defaultAvatarUrl: json['default_avatar_url'] as String? ?? '',
      userType: json['user_type'] as String? ?? '',
      type: json['type'] as String? ?? '',
      message: json['message'] as String? ?? '',
      channelName: json['channel_name'] as String? ?? '',
      channelType: json['channel_type'] as String? ?? '',
      currentStatus: json['current_status'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      edited: json['edited'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      pinnedDetails: (json['pinned_details'] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
      reactions: json['reactions'],
    );
  }

  ChannelMessage toEntity() => ChannelMessage(
    threadId: threadId,
    channelId: channelsId,
    orgId: orgId,
    username: username,
    status: status,
    createdAt: createdAt,
    updatedAt: updatedAt,
    messageCount: messageCount,
    lastReply: lastReply,
    avatarUrl: avatarUrl,
    defaultAvatarUrl: defaultAvatarUrl,
    userType: userType,
    type: type,
    messageHtml: message,
    channelName: channelName,
    channelType: channelType,
    currentStatus: currentStatus,
    fullName: fullName,
    email: email,
    userId: userId,
    edited: edited,
    isPinned: isPinned,
    pinnedDetails: pinnedDetails,
    reactions: reactions,
  );

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty || value == '0001-01-01T00:00:00Z') {
      return null;
    }

    return DateTime.tryParse(value)?.toUtc();
  }
}
