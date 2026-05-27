import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
// import 'package:zedu/core/network/file_repository.dart';

class ChatHistoryNotifier extends ChangeNotifier {
  final String channelId;
  final Ref ref;

  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  bool hasMore = true;
  int page = 1;

  String? editingMessageId;
  String? _editingOriginalContent;

  ChatHistoryNotifier(this.channelId, this.ref) {
    _loadInitial();
  }

  String get _currentUserId {
    final authState = ref.read(authNotifierProvider);
    return authState.user?.id ?? '';
  }

  String get currentUserName {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return 'You';
    final name = '${user.firstName} ${user.lastName}'.trim();
    return name.isNotEmpty ? name : user.username;
  }

  String? get currentUserAvatarUrl {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return null;
    return user.avatarUrl.isNotEmpty ? user.avatarUrl : user.defaultAvatarUrl;
  }

  bool isMyMessage(Map<String, dynamic> message) {
    final senderId = message['user_id'] ?? message['userId'];
    return senderId == _currentUserId || senderId == 'me';
  }

  String? get lastSentMessageContent {
    for (final msg in messages) {
      if (isMyMessage(msg) && msg['status'] != 'failed') {
        return msg['content'] as String?;
      }
    }
    return null;
  }

  String? get lastSentMessageId {
    for (final msg in messages) {
      if (isMyMessage(msg) && msg['status'] != 'failed') {
        return msg['id'] as String?;
      }
    }
    return null;
  }

  Future<void> _loadInitial() async {
    try {
      final repository = ref.read(dmRepositoryProvider);
      messages = await repository.getMessages(channelId, page: 1);
      hasMore = messages.length >= DmRepository.pageSize;
      page = 1;
    } catch (_) {
    } finally {
      isLoading = false;
      notifyListeners();
    }
    _subscribeToRealtimeMessages();
  }

  final Set<String> _seenIds = {};
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;

  /// Subscribe to real-time messages via Centrifugo instead of polling.
  void _subscribeToRealtimeMessages() {
    // Mark all existing messages as seen
    for (final m in messages) {
      final id = m['id']?.toString();
      if (id != null) _seenIds.add(id);
    }

    try {
      final realtimeService = ref.read(realtimeServiceProvider);
      // Subscribe to DM channel for real-time messages
      realtimeService.subscribeToDmChannel(channelId);
      _realtimeSubscription = realtimeService.dmMessageStream.listen((event) {
        if (event['channelId'] != channelId) return;
        final rawMessage = event['message'];
        if (rawMessage is! Map<String, dynamic>) return;

        if (_handleCallEvent(rawMessage)) return;

        final message = _extractRealtimeMessage(rawMessage);
        final id =
            message['id']?.toString() ?? message['message_id']?.toString();
        if (id != null && id.isNotEmpty && !_seenIds.add(id)) return;

        messages = [message, ...messages];
        notifyListeners();

        final senderName =
            message['username']?.toString() ??
            message['sender_name']?.toString() ??
            'Someone';
        ref
            .read(notificationServiceProvider)
            .handleIncomingMessage(message, channelId, senderName);
      });
      AppLogger.i(
        'Subscribed to real-time DM channel: $channelId',
        tag: 'ChatHistoryNotifier',
      );
    } catch (e) {
      AppLogger.e(
        'Failed to subscribe to real-time DM channel',
        tag: 'ChatHistoryNotifier',
        error: e,
      );
    }
  }

  Map<String, dynamic> _extractRealtimeMessage(Map<String, dynamic> event) {
    final payload = event['payload'];
    if (payload is Map<String, dynamic>) {
      final message = payload['message'];
      if (message is Map<String, dynamic>) return message;
      return payload;
    }
    final message = event['message'];
    if (message is Map<String, dynamic>) return message;
    return event;
  }

  bool _handleCallEvent(Map<String, dynamic> event) {
    final eventName = event['event']?.toString();
    final payload = event['payload'];
    if (eventName != 'direct_call_initiated' ||
        payload is! Map<String, dynamic>) {
      return false;
    }

    final callerId = payload['caller_id']?.toString() ?? '';
    if (callerId == _currentUserId) return true;

    ref
        .read(activeCallProvider)
        .receiveIncomingCall(
          buzzId: payload['buzz_id']?.toString() ?? '',
          remoteUserId: callerId,
          remoteUserName: payload['caller_name']?.toString() ?? 'Incoming call',
          channelId: payload['channel_id']?.toString() ?? channelId,
        );
    return true;
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadMore() async {
    if (isLoading || !hasMore) return;

    isLoading = true;
    notifyListeners();

    try {
      final repository = ref.read(dmRepositoryProvider);
      final nextPage = page + 1;
      final newMessages = await repository.getMessages(
        channelId,
        page: nextPage,
      );

      messages = [...messages, ...newMessages];
      hasMore = newMessages.length >= DmRepository.pageSize;
      page = nextPage;
    } catch (_) {
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(
    String content, {
    List<XFile>? media,
    List<dynamic>? mentions,
  }) async {
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final optimisticMessage = {
      "id": tempId,
      "content": content,
      "channel_id": channelId,
      "user_id": _currentUserId,
      "userId": _currentUserId,
      "type": "user",
      "created_at": DateTime.now().toIso8601String(),
      "status": "sending",
    };

    messages = [optimisticMessage, ...messages];
    notifyListeners();

    try {
      List<Map<String, dynamic>>? uploadedMedia;
      if (media != null && media.isNotEmpty) {
        final fileRepo = ref.read(fileRepositoryProvider);
        uploadedMedia = await fileRepo.uploadFiles(media);
      }

      final repository = ref.read(dmRepositoryProvider);
      await repository.sendMessage(
        channelId,
        content,
        media: uploadedMedia,
        mentions: mentions,
      );

      messages = messages.map((m) {
        if (m['id'] == tempId) {
          final newMsg = Map<String, dynamic>.from(m);
          newMsg.remove('status');
          if (uploadedMedia != null) {
            newMsg['media'] = uploadedMedia;
          }
          return newMsg;
        }
        return m;
      }).toList();
    } catch (e) {
      messages = messages.map((m) {
        if (m['id'] == tempId) {
          final newMsg = Map<String, dynamic>.from(m);
          newMsg['status'] = 'failed';
          newMsg['error'] = e.toString();
          return newMsg;
        }
        return m;
      }).toList();
    } finally {
      notifyListeners();
    }
  }

  Future<void> retryMessage(String messageId) async {
    final idx = messages.indexWhere((m) => m['id'] == messageId);
    if (idx == -1) return;

    final failedMsg = Map<String, dynamic>.from(messages[idx]);
    final content = failedMsg['content'] as String? ?? '';

    failedMsg['status'] = 'sending';
    messages = List<Map<String, dynamic>>.from(messages);
    messages[idx] = failedMsg;
    notifyListeners();

    try {
      final repository = ref.read(dmRepositoryProvider);
      await repository.sendMessage(channelId, content);

      messages = messages.map((m) {
        if (m['id'] == messageId) {
          final newMsg = Map<String, dynamic>.from(m);
          newMsg.remove('status');
          return newMsg;
        }
        return m;
      }).toList();
    } catch (_) {
      messages = messages.map((m) {
        if (m['id'] == messageId) {
          final newMsg = Map<String, dynamic>.from(m);
          newMsg['status'] = 'failed';
          return newMsg;
        }
        return m;
      }).toList();
    } finally {
      notifyListeners();
    }
  }

  void startEditing(String messageId) {
    final msg = messages.firstWhere(
      (m) => m['id'] == messageId,
      orElse: () => <String, dynamic>{},
    );
    if (msg.isEmpty) return;

    editingMessageId = messageId;
    _editingOriginalContent = msg['content'] as String?;
    notifyListeners();
  }

  void cancelEditing() {
    editingMessageId = null;
    _editingOriginalContent = null;
    notifyListeners();
  }

  Future<void> saveEdit(String messageId, String newContent) async {
    if (newContent.trim().isEmpty) {
      cancelEditing();
      return;
    }

    messages = messages.map((m) {
      if (m['id'] == messageId) {
        final updated = Map<String, dynamic>.from(m);
        updated['content'] = newContent;
        return updated;
      }
      return m;
    }).toList();
    editingMessageId = null;
    _editingOriginalContent = null;
    notifyListeners();

    try {
      final repository = ref.read(dmRepositoryProvider);
      await repository.editMessage(channelId, content: newContent);
    } catch (_) {
      if (_editingOriginalContent != null) {
        messages = messages.map((m) {
          if (m['id'] == messageId) {
            final reverted = Map<String, dynamic>.from(m);
            reverted['content'] = _editingOriginalContent;
            return reverted;
          }
          return m;
        }).toList();
        notifyListeners();
      }
    }
  }
}

final chatHistoryProvider =
    ChangeNotifierProvider.family<ChatHistoryNotifier, String>(
      (ref, channelId) => ChatHistoryNotifier(channelId, ref),
    );
