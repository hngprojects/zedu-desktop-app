import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

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
    if (channelId.startsWith('group-dm-') || channelId.contains('group-dm')) {
      _loadInitial();
      _listenToGroupDmChanges();
    } else {
      _loadInitial();
    }
  }

  void _listenToGroupDmChanges() {
    ref.listen<List<GroupDM>>(groupDmProvider, (previous, next) {
      final group = next.firstWhere(
        (g) => g.id == channelId,
        orElse: () => GroupDM(id: channelId, name: '', members: []),
      );
      messages = group.messages.reversed.map(_mapGroupDmMessageToHistoryMap).toList();
      notifyListeners();
    });
  }

  Map<String, dynamic> _mapGroupDmMessageToHistoryMap(String msg) {
    final isPending = msg.endsWith('(Pending...)');
    final isSimulated = msg.contains('simulated real-time');
    
    final senderId = isSimulated ? 'mock-member' : _currentUserId;
    final senderName = isSimulated ? 'Mock Member' : currentUserName;
    final content = isPending ? msg.substring(0, msg.length - 13) : msg;

    return {
      "id": msg.hashCode.toString(),
      "content": content,
      "channel_id": channelId,
      "user_id": senderId,
      "userId": senderId,
      "sender_name": senderName,
      "type": "user",
      "created_at": DateTime.now().toIso8601String(),
      if (isPending) "status": "sending",
    };
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
    if (channelId.startsWith('group-dm-') || channelId.contains('group-dm')) {
      try {
        final groups = ref.read(groupDmProvider);
        final group = groups.firstWhere(
          (g) => g.id == channelId,
          orElse: () => GroupDM(id: channelId, name: '', members: []),
        );
        messages = group.messages.reversed.map(_mapGroupDmMessageToHistoryMap).toList();
      } catch (e, stack) {
        AppLogger.e('Error loading initial Group DM messages', error: e, stackTrace: stack);
      } finally {
        isLoading = false;
        notifyListeners();
      }
      return;
    }

    try {
      final repository = ref.read(dmRepositoryProvider);
      messages = await repository.getMessages(channelId, page: 1);
      hasMore = messages.length >= DmRepository.pageSize;
      page = 1;
    } catch (e, stack) {
      AppLogger.e('Error loading initial DM/channel messages', error: e, stackTrace: stack);
    } finally {
      isLoading = false;
      notifyListeners();
    }
    // Start polling for new messages now that the initial load is done.
    _startPolling();
  }

  // ── Realtime notification polling ────────────────────────────────────────────

  /// Set of message IDs we have already seen. Used to detect truly-new messages
  /// so we don't re-fire a notification on every poll cycle.
  final Set<String> _seenIds = {};

  /// Keep track of the polling timer so we can cancel it on dispose.
  // ignore: cancel_subscriptions
  dynamic _pollingTimer;

  void _startPolling() {
    // Record all initially-loaded IDs as "already seen" so we only notify
    // about messages that arrive AFTER the initial load.
    for (final m in messages) {
      final id = m['id']?.toString();
      if (id != null) _seenIds.add(id);
    }

    // Poll every 10 seconds for new messages.
    _pollingTimer = Stream<int>.periodic(const Duration(seconds: 10)).listen((
      _,
    ) {
      _pollForNewMessages();
    });
  }

  Future<void> _pollForNewMessages() async {
    try {
      final repository = ref.read(dmRepositoryProvider);
      final fresh = await repository.getMessages(channelId, page: 1);

      bool hadNew = false;
      for (final msg in fresh) {
        final id = msg['id']?.toString();
        if (id == null || _seenIds.contains(id)) continue;

        _seenIds.add(id);
        hadNew = true;

        // Only notify for messages from other users.
        if (!isMyMessage(msg)) {
          final senderName =
              (msg['sender_name'] ?? msg['username'] ?? 'Someone').toString();
          ref
              .read(notificationServiceProvider)
              .handleIncomingMessage(msg, channelId, senderName);
        }
      }

      if (hadNew) {
        // Prepend only the genuinely new messages at the top.
        final existingIds = messages.map((m) => m['id']?.toString()).toSet();
        final newOnly = fresh
            .where((m) => !existingIds.contains(m['id']?.toString()))
            .toList();
        if (newOnly.isNotEmpty) {
          messages = [...newOnly, ...messages];
          notifyListeners();
        }
      }
    } catch (_) {
      // Silent — polling failures should not surface to the UI.
    }
  }

  @override
  void dispose() {
    (_pollingTimer as dynamic)?.cancel();
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
      if (media != null && media.isNotEmpty)
        "media": media.map((file) => {
          "file_name": file.name,
          "file_link": file.path,
          "file_type": file.name.split('.').last,
        }).toList(),
    };

    messages = [optimisticMessage, ...messages];
    notifyListeners();

    if (channelId.startsWith('group-dm-') || channelId.contains('group-dm')) {
      try {
        final notifier = ref.read(groupDmProvider.notifier);
        await notifier.sendMessage(channelId, content);
        
        messages = messages.map((m) {
          if (m['id'] == tempId) {
            final newMsg = Map<String, dynamic>.from(m);
            newMsg.remove('status');
            return newMsg;
          }
          return m;
        }).toList();
      } catch (e, stack) {
        AppLogger.e('Error sending Group DM message', error: e, stackTrace: stack);
        messages = messages.map((m) {
          if (m['id'] == tempId) {
            final newMsg = Map<String, dynamic>.from(m);
            newMsg['status'] = 'failed';
            return newMsg;
          }
          return m;
        }).toList();
      } finally {
        notifyListeners();
      }
      return;
    }

    try {
      final repository = ref.read(dmRepositoryProvider);
      await repository.sendMessage(
        channelId,
        content,
        media: media,
        mentions: mentions,
      );

      messages = messages.map((m) {
        if (m['id'] == tempId) {
          final newMsg = Map<String, dynamic>.from(m);
          newMsg.remove('status');
          return newMsg;
        }
        return m;
      }).toList();
    } catch (e, stack) {
      AppLogger.e('Error sending DM/channel message', error: e, stackTrace: stack);
      messages = messages.map((m) {
        if (m['id'] == tempId) {
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

  Future<void> retryMessage(String messageId) async {
    final idx = messages.indexWhere((m) => m['id'] == messageId);
    if (idx == -1) return;

    final failedMsg = Map<String, dynamic>.from(messages[idx]);
    final content = failedMsg['content'] as String? ?? '';

    failedMsg['status'] = 'sending';
    messages = List<Map<String, dynamic>>.from(messages);
    messages[idx] = failedMsg;
    notifyListeners();

    if (channelId.startsWith('group-dm-') || channelId.contains('group-dm')) {
      try {
        final notifier = ref.read(groupDmProvider.notifier);
        await notifier.sendMessage(channelId, content);

        messages = messages.map((m) {
          if (m['id'] == messageId) {
            final newMsg = Map<String, dynamic>.from(m);
            newMsg.remove('status');
            return newMsg;
          }
          return m;
        }).toList();
      } catch (e, stack) {
        AppLogger.e('Error retrying Group DM message', error: e, stackTrace: stack);
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
      return;
    }

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
    } catch (e, stack) {
      AppLogger.e('Error retrying DM/channel message', error: e, stackTrace: stack);
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
        updated['is_edited'] = true;
        updated['edited'] = true;
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
            reverted.remove('is_edited');
            reverted.remove('edited');
            return reverted;
          }
          return m;
        }).toList();
        notifyListeners();
      }
    }
  }

  Future<void> deleteMessage(String messageId) async {
    messages = messages.where((m) => m['id'] != messageId).toList();
    notifyListeners();

    try {
      final repository = ref.read(dmRepositoryProvider);
      await repository.deleteMessage(channelId, messageId);
      ref.read(pinnedMessagesProvider.notifier).unpinMessage(channelId, messageId);
    } catch (e, stack) {
      AppLogger.e('Error deleting message', error: e, stackTrace: stack);
    }
  }

  void toggleReaction(String messageId, String emoji, String userId) {
    messages = messages.map((m) {
      if (m['id'] == messageId) {
        final updated = Map<String, dynamic>.from(m);
        final reactions = Map<String, dynamic>.from(
          (updated['reactions'] as Map?) ?? <String, dynamic>{},
        );
        final userList = List<String>.from(
          (reactions[emoji] as Iterable?) ?? <String>[],
        );
        if (userList.contains(userId)) {
          userList.remove(userId);
        } else {
          userList.add(userId);
        }
        if (userList.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = userList;
        }
        updated['reactions'] = reactions;
        return updated;
      }
      return m;
    }).toList();
    notifyListeners();
  }
}

final chatHistoryProvider =
    ChangeNotifierProvider.family<ChatHistoryNotifier, String>(
      (ref, channelId) => ChatHistoryNotifier(channelId, ref),
    );
