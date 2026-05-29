import 'dart:async';
import 'dart:math' as math;

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ChatHistoryNotifier extends ChangeNotifier {
  final String channelId;
  final Ref ref;

  /// The real server-assigned channel ID.
  /// Starts as [channelId] (which may be a placeholder) and is resolved
  /// during [_loadInitial]. All network calls must use this value.
  late String _resolvedChannelId;

  /// Completes with the resolved channel ID once the channel is ready.
  /// [sendMessage] awaits this so messages typed immediately after navigation
  /// are queued rather than rejected.
  final Completer<String> _channelReadyCompleter = Completer<String>();

  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  bool hasMore = true;
  int page = 1;

  String? editingMessageId;
  String? _editingOriginalContent;

  ChatHistoryNotifier(this.channelId, this.ref) {
    _resolvedChannelId = channelId;
    _loadInitial();
  }

  // ---------------------------------------------------------------------------
  // Auth helpers
  // ---------------------------------------------------------------------------

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
      // ── Step 1: resolve the channel ID ────────────────────────────────────
      // If the ID passed in is already valid (existing conversation tapped in
      // the sidebar), use it directly.  Otherwise the conversation was just
      // created inside DmSidebarList and the real ID is already stored in
      // DmConversation — so we should never actually hit the creation path
      // here.  This is a last-resort safety net only.
      if (DmRepository.isValidChannelId(channelId)) {
        _resolvedChannelId = channelId;
      } else {
        // Should not normally happen because DmSidebarList now ensures a valid
        // channelId before navigating.  Log a warning and surface the error
        // cleanly instead of silently failing later.
        AppLogger.w(
          'ChatHistoryNotifier received invalid channelId: "$channelId". '
          'Channel creation should happen in DmSidebarList before navigation.',
          tag: 'ChatHistoryNotifier',
        );
        // Complete with an error so sendMessage surfaces a readable failure
        // rather than an infinite wait.
        _channelReadyCompleter.completeError(
          const ApiFailure(
            message:
                'Cannot send message: the conversation is still being set up. '
                'Please go back and tap the contact again.',
            kind: ApiFailureKind.client,
          ),
        );
        isLoading = false;
        notifyListeners();
        return;
      }

      // ── Step 2: signal that the channel is ready ──────────────────────────
      if (!_channelReadyCompleter.isCompleted) {
        _channelReadyCompleter.complete(_resolvedChannelId);
      }

      // ── Step 3: load message history ─────────────────────────────────────
      final repository = ref.read(dmRepositoryProvider);
      messages = await repository.getMessages(_resolvedChannelId, page: 1);
      hasMore = messages.length >= DmRepository.pageSize;
      page = 1;
    } catch (e) {
      if (!_channelReadyCompleter.isCompleted) {
        _channelReadyCompleter.completeError(e);
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }

    _subscribeToRealtimeMessages();
  }

  // ---------------------------------------------------------------------------
  // Real-time subscription
  // ---------------------------------------------------------------------------

  final Set<String> _seenIds = {};
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;

  void _subscribeToRealtimeMessages() {
    // Mark all existing messages as seen to avoid duplicates.
    for (final m in messages) {
      final id = m['id']?.toString();
      if (id != null) _seenIds.add(id);
    }

    // Only subscribe when we have a real server channel ID.
    if (!DmRepository.isValidChannelId(_resolvedChannelId)) {
      AppLogger.w(
        'Skipping real-time subscription — invalid channelId: "$_resolvedChannelId"',
        tag: 'ChatHistoryNotifier',
      );
      return;
    }

    try {
      final realtimeService = ref.read(realtimeServiceProvider);
      realtimeService.subscribeToDmChannel(_resolvedChannelId);

      _realtimeSubscription = realtimeService.dmMessageStream.listen((event) {
        AppLogger.d(
          'Realtime event for channel ${event['channelId']}',
          tag: 'ChatHistoryNotifier',
        );
        if (event['channelId'] != _resolvedChannelId) return;

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
            .handleIncomingMessage(message, _resolvedChannelId, senderName);
      });

      AppLogger.i(
        'Subscribed to real-time DM channel: $_resolvedChannelId',
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

  // ---------------------------------------------------------------------------
  // Message extraction helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _extractRealtimeMessage(Map<String, dynamic> event) {
    final payload = event['payload'];
    Map<String, dynamic> msg;
    if (payload is Map<String, dynamic>) {
      final message = payload['message'];
      msg = message is Map<String, dynamic>
          ? Map<String, dynamic>.from(message)
          : Map<String, dynamic>.from(payload);
    } else {
      final message = event['message'];
      msg = message is Map<String, dynamic>
          ? Map<String, dynamic>.from(message)
          : Map<String, dynamic>.from(event);
    }

    // Normalize field names to match what the UI expects
    if ((!msg.containsKey('id') || (msg['id']?.toString() ?? '').isEmpty) &&
        msg.containsKey('thread_id')) {
      msg['id'] = msg['thread_id'];
    }
    final currentContent = msg['content']?.toString() ?? '';
    if (currentContent.isEmpty &&
        msg.containsKey('message') &&
        msg['message'] is String &&
        (msg['message'] as String).isNotEmpty) {
      msg['content'] = msg['message'];
    }
    if (!msg.containsKey('created_at') && msg.containsKey('createdAt')) {
      msg['created_at'] = msg['createdAt'];
    }
    if (!msg.containsKey('user_id') && msg.containsKey('userId')) {
      msg['user_id'] = msg['userId'];
    }

    return msg;
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
          channelId: payload['channel_id']?.toString() ?? _resolvedChannelId,
        );
    return true;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Pagination
  // ---------------------------------------------------------------------------

  Future<void> loadMore() async {
    if (isLoading || !hasMore) return;

    isLoading = true;
    notifyListeners();

    try {
      final repository = ref.read(dmRepositoryProvider);
      final nextPage = page + 1;
      final newMessages = await repository.getMessages(
        _resolvedChannelId,
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

  // ---------------------------------------------------------------------------
  // Send / Retry
  // ---------------------------------------------------------------------------

  Future<void> sendMessage(
    String content, {
    List<XFile>? media,
    List<dynamic>? mentions,
  }) async {
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final optimisticMessage = {
      'id': tempId,
      'content': content,
      'channel_id': channelId,
      'user_id': _currentUserId,
      'userId': _currentUserId,
      'type': 'user',
      'created_at': DateTime.now().toIso8601String(),
      'status': 'sending',
    };

    messages = [optimisticMessage, ...messages];
    notifyListeners();

    try {
      // Wait for channel resolution (handles the race where the user types
      // before _loadInitial finishes).
      final resolvedId = await _channelReadyCompleter.future;

      List<Map<String, dynamic>>? formattedMedia;
      if (media != null && media.isNotEmpty) {
        final fileRepo = ref.read(fileRepositoryProvider);
        final uploaded = await fileRepo.uploadFiles(media);

        formattedMedia = [];
        for (int i = 0; i < uploaded.length; i++) {
          final up = uploaded[i];
          final xfile = media[i];

          final fileUrl = up['file_link'] ?? up['file_url'] ?? up['url'] ?? '';
          final fileName = up['file_name'] ?? xfile.name;
          final fileType = up['file_type'] ?? xfile.name.split('.').last;
          String fileId = up['id']?.toString() ?? '';
          if (fileId.isEmpty) {
            final random = math.Random();
            const hexDigits = '0123456789abcdef';
            String randomHex(int length) => List.generate(length, (_) => hexDigits[random.nextInt(16)]).join();
            fileId = '${randomHex(8)}-${randomHex(4)}-4${randomHex(3)}-a${randomHex(3)}-${randomHex(12)}';
          }

          formattedMedia.add({
            'id': fileId,
            'file_name': fileName,
            'file_type': fileType,
            'file_link': fileUrl,
          });
        }
      }

      final repository = ref.read(dmRepositoryProvider);
      final serverMsg = await repository.sendMessage(
        resolvedId,
        content,
        media: formattedMedia,
        mentions: mentions,
      );

      if (serverMsg != null) {
        AppLogger.d(
          'Reconciling optimistic message $tempId with server message ${serverMsg['id'] ?? serverMsg['message_id']}',
          tag: 'ChatHistoryNotifier',
        );
        messages = messages.map((m) {
          if (m['id'] == tempId) {
            final newMsg = Map<String, dynamic>.from(m);
            // Merge server fields, preferring server values.
            newMsg.addAll(serverMsg.map((k, v) => MapEntry(k.toString(), v)));
            // Normalize id key if server uses message_id
            final serverId = serverMsg['id'] ?? serverMsg['message_id'];
            if (serverId != null) newMsg['id'] = serverId.toString();
            // Normalize created timestamp
            newMsg['created_at'] =
                serverMsg['created_at'] ??
                serverMsg['createdAt'] ??
                newMsg['created_at'];
            newMsg.remove('status');
            // Mark as seen to prevent duplicate from realtime stream
            final sid = newMsg['id']?.toString();
            if (sid != null) _seenIds.add(sid);
            return newMsg;
          }
          return m;
        }).toList();
      } else {
        messages = messages.map((m) {
          if (m['id'] == tempId) {
            final newMsg = Map<String, dynamic>.from(m);
            newMsg.remove('status');
            if (formattedMedia != null) newMsg['media'] = formattedMedia;
            return newMsg;
          }
          return m;
        }).toList();
      }
    } catch (e, stacktrace) {
      debugPrint('Message Send Error: $e\n$stacktrace');
      AppLogger.e(
        'Message Send Error',
        tag: 'ChatHistoryNotifier',
        error: e,
        stackTrace: stacktrace,
      );
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
    messages = List<Map<String, dynamic>>.from(messages)..[idx] = failedMsg;
    notifyListeners();

    try {
      // Use the resolved channel ID, not the original placeholder.
      final resolvedId = await _channelReadyCompleter.future;
      final repository = ref.read(dmRepositoryProvider);
      final serverMsg = await repository.sendMessage(resolvedId, content);

      if (serverMsg != null) {
        AppLogger.d(
          'Retry reconciled for $messageId -> server ${serverMsg['id'] ?? serverMsg['message_id']}',
          tag: 'ChatHistoryNotifier',
        );
        messages = messages.map((m) {
          if (m['id'] == messageId) {
            final newMsg = Map<String, dynamic>.from(m);
            newMsg.addAll(serverMsg.map((k, v) => MapEntry(k.toString(), v)));
            final serverId = serverMsg['id'] ?? serverMsg['message_id'];
            if (serverId != null) newMsg['id'] = serverId.toString();
            newMsg['created_at'] =
                serverMsg['created_at'] ??
                serverMsg['createdAt'] ??
                newMsg['created_at'];
            newMsg.remove('status');
            final sid = newMsg['id']?.toString();
            if (sid != null) _seenIds.add(sid);
            return newMsg;
          }
          return m;
        }).toList();
      } else {
        messages = messages.map((m) {
          if (m['id'] == messageId) {
            final newMsg = Map<String, dynamic>.from(m);
            newMsg.remove('status');
            return newMsg;
          }
          return m;
        }).toList();
      }
    } catch (e, stacktrace) {
      debugPrint('Message Retry Error: $e\n$stacktrace');
      AppLogger.e(
        'Message Retry Error',
        tag: 'ChatHistoryNotifier',
        error: e,
        stackTrace: stacktrace,
      );
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

  // ---------------------------------------------------------------------------
  // Edit
  // ---------------------------------------------------------------------------

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
      final resolvedId = await _channelReadyCompleter.future;
      final repository = ref.read(dmRepositoryProvider);
      await repository.editMessage(resolvedId, content: newContent);
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
