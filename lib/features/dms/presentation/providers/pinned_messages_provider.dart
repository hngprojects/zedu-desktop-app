import 'package:zedu/core/core.dart';

class PinnedMessage {
  final String id;
  final String content;
  final String senderName;
  final String pinnedBy;
  final DateTime pinnedAt;
  final String channelId;

  const PinnedMessage({
    required this.id,
    required this.content,
    required this.senderName,
    required this.pinnedBy,
    required this.pinnedAt,
    required this.channelId,
  });

  factory PinnedMessage.fromJson(Map<String, dynamic> json) {
    return PinnedMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      senderName: json['sender_name'] as String? ?? 'Someone',
      pinnedBy: json['pinned_by'] as String? ?? 'Admin',
      pinnedAt: json['pinned_at'] != null
          ? DateTime.parse(json['pinned_at'] as String)
          : DateTime.now(),
      channelId: json['channel_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender_name': senderName,
      'pinned_by': pinnedBy,
      'pinned_at': pinnedAt.toIso8601String(),
      'channel_id': channelId,
    };
  }
}

class PinnedMessagesNotifier
    extends Notifier<Map<String, List<PinnedMessage>>> {
  @override
  Map<String, List<PinnedMessage>> build() {
    return {};
  }

  void pinMessage(String channelId, PinnedMessage message) {
    final current = state[channelId] ?? [];
    if (current.any((m) => m.id == message.id)) return;

    final updated = List<PinnedMessage>.from(current);
    if (updated.length >= 20) {
      updated.removeAt(0);
    }
    updated.add(message);
    state = {...state, channelId: updated};
  }

  void unpinMessage(String channelId, String messageId) {
    final current = state[channelId] ?? [];
    if (!current.any((m) => m.id == messageId)) return;

    final updated = current.where((m) => m.id != messageId).toList();
    state = {...state, channelId: updated};
  }
}

final pinnedMessagesProvider =
    NotifierProvider<PinnedMessagesNotifier, Map<String, List<PinnedMessage>>>(
      PinnedMessagesNotifier.new,
    );
