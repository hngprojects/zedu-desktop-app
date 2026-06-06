import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ChatHistoryNotifier extends ChangeNotifier {
  String channelId;
  final String? threadId;
  final Ref ref;

  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  bool hasMore = true;
  int page = 1;

  String? editingMessageId;
  String? _editingOriginalContent;
  StreamSubscription<ChatWebsocketMessage>? _websocketSubscription;
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;

  ChatHistoryNotifier(String channelOrThreadId, this.ref)
    : channelId = channelOrThreadId.contains(':')
          ? channelOrThreadId.split(':').first
          : channelOrThreadId,
      threadId = channelOrThreadId.contains(':')
          ? channelOrThreadId.split(':').last
          : null {
    ref.read(chatWebsocketProvider).connect([channelId]);
    _listenToWebsocket();

    _loadInitial();
    if (!(channelId.startsWith('group-dm-') ||
        channelId.contains('group-dm'))) {
      _listenToCentrifugo();
    }
  }

  void _listenToCentrifugo() {
    // Ensure we are subscribed to this channel via Centrifugo.
    ref.read(realtimeServiceProvider).subscribeToDmChannel(channelId);

    _realtimeSubscription = ref
        .read(realtimeServiceProvider)
        .dmMessageStream
        .listen((event) {
          if (event['channelId'] != channelId) return;
          final msg = event['message'];
          if (msg is! Map<String, dynamic>) return;

          final id = msg['id']?.toString();
          if (id == null || id.isEmpty) return;

          // Try to reconcile with an existing optimistic message first.
          bool foundMatch = false;
          final content = (msg['content'] ?? msg['text'] ?? '').toString();
          final authorId = (msg['user_id'] ?? msg['sender_id'] ?? '')
              .toString();
          final authorName = (msg['sender_name'] ?? msg['username'] ?? '')
              .toString();

          messages = messages.map((m) {
            if (m['id'] == id) {
              foundMatch = true;
              return m;
            }
            if (!foundMatch &&
                m['content'] == content &&
                (m['user_id'] == authorId ||
                    m['sender_name'] == authorName ||
                    m['username'] == authorName)) {
              foundMatch = true;
              return Map<String, dynamic>.from(m)
                ..['id'] = id
                ..['user_id'] = authorId.isNotEmpty ? authorId : m['user_id']
                ..remove('status');
            }
            return m;
          }).toList();

          if (!foundMatch) {
            if (_seenIds.contains(id)) return;
            _seenIds.add(id);
            messages = [msg, ...messages];

            // Update DM list sidebar.
            ref.read(dmListProvider.notifier).onNewMessage(channelId, msg);

            // Trigger a local notification for messages from others.
            final currentUserId = ref.read(authNotifierProvider).user?.id ?? '';
            if (authorId != currentUserId && authorId.isNotEmpty) {
              ref
                  .read(notificationServiceProvider)
                  .handleIncomingMessage(msg, channelId, authorName);
            }
          }

          notifyListeners();
        });
  }

  void _listenToWebsocket() {
    _websocketSubscription = ref
        .read(chatWebsocketProvider)
        .messageStream
        .listen((msg) {
          if (msg.groupDmId == channelId) {
            final authState = ref.read(authNotifierProvider);
            final currentUser = authState.user;
            final currentUsername = currentUser?.username;
            final isMe =
                msg.authorName == currentUserName ||
                (currentUsername != null && msg.authorName == currentUsername);

            bool foundMatch = false;
            messages = messages.map((m) {
              if (m['id'] == msg.id) {
                foundMatch = true;
                return m;
              }
              // Match optimistic messages
              if (!foundMatch &&
                  m['content'] == msg.text &&
                  (m['sender_name'] == msg.authorName ||
                      m['username'] == msg.authorName)) {
                // Update optimistic message with real ID
                final updated = Map<String, dynamic>.from(m);
                updated['id'] = msg.id;
                if (msg.userId.isNotEmpty) {
                  updated['user_id'] = msg.userId;
                  updated['userId'] = msg.userId;
                }
                foundMatch = true;
                return updated;
              }
              return m;
            }).toList();

            if (!foundMatch) {
              final newMsg = {
                "id": msg.id,
                "content": msg.text,
                "channel_id": channelId,
                "user_id": msg.userId.isNotEmpty
                    ? msg.userId
                    : (isMe ? _currentUserId : 'other'),
                "userId": msg.userId.isNotEmpty
                    ? msg.userId
                    : (isMe ? _currentUserId : 'other'),
                "sender_name": msg.authorName,
                "username": msg.authorName,
                "type": "user",
                "created_at": msg.timestamp.toUtc().toIso8601String(),
              };
              messages = [newMsg, ...messages];
              _seenIds.add(msg.id);
            }
            notifyListeners();
          }
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
      "created_at": DateTime.now().toUtc().toIso8601String(),
      if (isPending) "status": "sending",
    };
  }

  bool get _isGroupDm {
    final activeChat = ref.read(activeChatProvider);
    if (activeChat.type == ActiveChatType.groupDm &&
        activeChat.id == channelId) {
      return true;
    }
    if (channelId.startsWith('group-dm-') || channelId.contains('group-dm')) {
      return true;
    }
    final groups = ref.read(groupDmProvider);
    return groups.any((g) => g.id == channelId);
  }

  bool get _isChannel {
    try {
      final state = ref.read(channelProvider);
      return state.channels.any((c) => c.id == channelId);
    } catch (_) {
      return false;
    }
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
    var rawSender =
        message['user_id'] ??
        message['userId'] ??
        message['sender_id'] ??
        message['author_id'];

    if (rawSender == null && message['sender'] is Map) {
      rawSender = (message['sender'] as Map)['id'];
    }

    final senderId = rawSender?.toString() ?? '';
    final currentId = _currentUserId;
    if (currentId.isEmpty) return false;
    return senderId == currentId || senderId == 'me';
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
        messages = group.messages.reversed
            .map(_mapGroupDmMessageToHistoryMap)
            .toList();
      } catch (e, stack) {
        AppLogger.e(
          'Error loading initial Group DM messages',
          error: e,
          stackTrace: stack,
        );
      } finally {
        isLoading = false;
        notifyListeners();
      }
      return;
    }

    try {
      final repository = ref.read(dmRepositoryProvider);
      final cType = _isGroupDm
          ? 'group_dm'
          : _isChannel
          ? 'channel'
          : 'dm';
      messages = await repository.getMessages(
        channelId,
        page: 1,
        threadId: threadId,
        channelType: cType,
      );
      hasMore = messages.length >= DmRepository.pageSize;
      page = 1;
    } catch (e, stack) {
      AppLogger.e(
        'Error loading initial DM/channel messages',
        error: e,
        stackTrace: stack,
      );

      if (_isGroupDm) {
        try {
          final groups = ref.read(groupDmProvider);
          final group = groups.firstWhere(
            (g) => g.id == channelId,
            orElse: () => GroupDM(id: channelId, name: '', members: []),
          );
          if (group.messages.isNotEmpty) {
            messages = group.messages.reversed
                .map(_mapGroupDmMessageToHistoryMap)
                .toList();
          }
        } catch (localError) {
          AppLogger.e(
            'Error loading fallback Group DM messages',
            error: localError,
          );
        }
      }

      if (e is ApiFailure && (e.statusCode == 400 || e.statusCode == 403)) {
        AppLogger.i(
          'Not a member of channel $channelId. Attempting auto-join.',
        );
        try {
          final joined = await ref
              .read(channelProvider.notifier)
              .joinChannel(channelId);
          if (joined) {
            final repository = ref.read(dmRepositoryProvider);
            messages = await repository.getMessages(
              channelId,
              page: 1,
              threadId: threadId,
            );
            hasMore = messages.length >= DmRepository.pageSize;
            page = 1;
          }
        } catch (joinError) {
          AppLogger.e(
            'Failed to auto-join channel $channelId',
            error: joinError,
          );
        }
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }

    _startPolling();
  }

  final Set<String> _seenIds = {};

  dynamic _pollingTimer;

  void _startPolling() {
    for (final m in messages) {
      final id = m['id']?.toString();
      if (id != null) _seenIds.add(id);
    }

    _pollingTimer = Stream<int>.periodic(const Duration(seconds: 30), (i) => i)
        .listen((_) {
          _pollForNewMessages();
        });
  }

  Future<void> _pollForNewMessages() async {
    try {
      final repository = ref.read(dmRepositoryProvider);
      final fresh = await repository.getMessages(
        channelId,
        page: 1,
        threadId: threadId,
      );

      bool hadNew = false;
      for (final msg in fresh) {
        final id = msg['id']?.toString();
        if (id == null || _seenIds.contains(id)) continue;

        _seenIds.add(id);
        hadNew = true;

        if (!isMyMessage(msg)) {
          final senderName =
              (msg['sender_name'] ?? msg['username'] ?? 'Someone').toString();
          ref
              .read(notificationServiceProvider)
              .handleIncomingMessage(msg, channelId, senderName);
        }
      }

      if (hadNew) {
        final existingIds = messages.map((m) => m['id']?.toString()).toSet();
        final newOnly = fresh
            .where((m) => !existingIds.contains(m['id']?.toString()))
            .toList();
        if (newOnly.isNotEmpty) {
          messages = [...newOnly, ...messages];
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    (_pollingTimer as dynamic)?.cancel();
    _websocketSubscription?.cancel();
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
      final cType = _isGroupDm
          ? 'group_dm'
          : _isChannel
          ? 'channel'
          : 'dm';
      final newMessages = await repository.getMessages(
        channelId,
        page: nextPage,
        threadId: threadId,
        channelType: cType,
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
      "created_at": DateTime.now().toUtc().toIso8601String(),
      "status": "sending",
      if (media != null && media.isNotEmpty)
        "media": media
            .map(
              (file) => {
                "file_name": file.name,
                "file_link": file.path,
                "file_type": file.name.split('.').last,
              },
            )
            .toList(),
    };

    messages = [optimisticMessage, ...messages];
    notifyListeners();

    if (_isGroupDm) {
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
        AppLogger.e(
          'Error sending Group DM message',
          error: e,
          stackTrace: stack,
        );
        messages = messages.map((m) {
          if (m['id'] == tempId) {
            final newMsg = Map<String, dynamic>.from(m);
            newMsg['status'] = 'failed: $e';
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
      String activeChannelId = channelId;

      final selectedDm = ref.read(selectedDmProvider);
      final activeChat = ref.read(activeChatProvider);
      final isDirectMessage = activeChat.type == ActiveChatType.directMessage;

      if (isDirectMessage &&
          selectedDm != null &&
          selectedDm.channelId == selectedDm.participantId) {
        final orgId = ref.read(currentOrgIdProvider);
        final roomData = await repository.createDmChannel(
          orgId: orgId,
          userId: selectedDm.participantId,
        );
        final newChannelId = roomData.channelId;
        if (newChannelId.isNotEmpty) {
          activeChannelId = newChannelId;
          channelId = newChannelId;
          final updatedDm = DmConversation(
            channelId: newChannelId,
            username: selectedDm.username,
            participantId: selectedDm.participantId,
            participantEmail: selectedDm.participantEmail,
            avatarUrl: selectedDm.avatarUrl,
            defaultAvatarUrl: selectedDm.defaultAvatarUrl,
            channelType: 'dm',
            previewMessage: content,
            unreadCount: 0,
          );
          ref.read(selectedDmProvider.notifier).select(updatedDm);
          ref.read(dmListProvider.notifier).refresh();
        }
      }

      final cType = isDirectMessage
          ? 'dm'
          : _isChannel
          ? 'channel'
          : 'group_dm';

      var responseData = <String, dynamic>{};

      List<Map<String, dynamic>> uploadedMedia = [];
      if (media != null && media.isNotEmpty) {
        final fileRepo = ref.read(fileRepositoryProvider);
        uploadedMedia = await fileRepo.uploadFiles(media);
      }

      try {
        final orgId = ref.read(currentOrgIdProvider);
        responseData = await repository.sendMessage(
          activeChannelId,
          content,
          orgId: orgId,
          threadId: threadId,
          media: uploadedMedia,
          mentions: mentions,
          channelType: cType,
        );
      } catch (e) {
        if (e is ApiFailure && (e.statusCode == 400 || e.statusCode == 403)) {
          AppLogger.i(
            'Not a member of channel $activeChannelId on sendMessage. Auto-joining.',
          );
          final joined = await ref
              .read(channelProvider.notifier)
              .joinChannel(activeChannelId);
          if (joined) {
            responseData = await repository.sendMessage(
              activeChannelId,
              content,
              orgId: ref.read(currentOrgIdProvider),
              threadId: threadId,
              media: uploadedMedia,
              mentions: mentions,
              channelType: cType,
            );
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      messages = messages.map((m) {
        if (m['id'] == tempId) {
          final newMsg = Map<String, dynamic>.from(m);
          newMsg.remove('status');
          if (responseData.isNotEmpty) {
            for (final entry in responseData.entries) {
              if (entry.value != null && entry.value.toString().isNotEmpty) {
                newMsg[entry.key] = entry.value;
              }
            }
            if (responseData.containsKey('id')) {
              newMsg['id'] = responseData['id'];
            }
          }
          return newMsg;
        }
        return m;
      }).toList();
    } catch (e, stack) {
      AppLogger.e(
        'Error sending DM/channel message',
        error: e,
        stackTrace: stack,
      );
      messages = messages.map((m) {
        if (m['id'] == tempId) {
          final newMsg = Map<String, dynamic>.from(m);
          newMsg['status'] = 'failed: $e';
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

    if (_isGroupDm) {
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
        AppLogger.e(
          'Error retrying Group DM message',
          error: e,
          stackTrace: stack,
        );
        messages = messages.map((m) {
          if (m['id'] == messageId) {
            final newMsg = Map<String, dynamic>.from(m);
            newMsg['status'] = 'failed: $e';
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
      final rawMedia = failedMsg['media'] as List<dynamic>?;
      final mediaFiles = rawMedia?.map((m) {
        final map = m as Map<dynamic, dynamic>;
        final path = (map['file_link'] ?? map['path'] ?? '').toString();
        final name = (map['file_name'] ?? map['name'] ?? 'file').toString();
        return XFile(path, name: name);
      }).toList();

      final activeChat = ref.read(activeChatProvider);
      final isDirectMessage = activeChat.type == ActiveChatType.directMessage;
      final cType = isDirectMessage
          ? 'dm'
          : _isChannel
          ? 'channel'
          : 'group_dm';

      var responseData = <String, dynamic>{};

      List<Map<String, dynamic>> uploadedMedia = [];
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        final fileRepo = ref.read(fileRepositoryProvider);
        uploadedMedia = await fileRepo.uploadFiles(mediaFiles);
      }

      try {
        responseData = await repository.sendMessage(
          channelId,
          content,
          orgId: ref.read(currentOrgIdProvider),
          threadId: threadId,
          media: uploadedMedia,
          channelType: cType,
        );
      } catch (e) {
        if (e is ApiFailure && (e.statusCode == 400 || e.statusCode == 403)) {
          AppLogger.i(
            'Not a member of channel $channelId on retryMessage. Auto-joining.',
          );
          final joined = await ref
              .read(channelProvider.notifier)
              .joinChannel(channelId);
          if (joined) {
            responseData = await repository.sendMessage(
              channelId,
              content,
              orgId: ref.read(currentOrgIdProvider),
              threadId: threadId,
              media: uploadedMedia,
              channelType: cType,
            );
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      messages = messages.map((m) {
        if (m['id'] == messageId) {
          final newMsg = Map<String, dynamic>.from(m);
          newMsg.remove('status');
          if (responseData.isNotEmpty) {
            for (final entry in responseData.entries) {
              if (entry.value != null && entry.value.toString().isNotEmpty) {
                newMsg[entry.key] = entry.value;
              }
            }
            if (responseData.containsKey('id')) {
              newMsg['id'] = responseData['id'];
            }
          }
          return newMsg;
        }
        return m;
      }).toList();
    } catch (e, stack) {
      AppLogger.e(
        'Error retrying DM/channel message',
        error: e,
        stackTrace: stack,
      );
      messages = messages.map((m) {
        if (m['id'] == messageId) {
          final newMsg = Map<String, dynamic>.from(m);
          newMsg['status'] = 'failed: $e';
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

    // Save before clearing for revert in catch
    final originalContent = _editingOriginalContent;

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
      await repository.editMessage(
        channelId,
        messageId: messageId,
        content: newContent,
      );
    } catch (_) {
      if (originalContent != null) {
        // ← now correctly uses local var
        messages = messages.map((m) {
          if (m['id'] == messageId) {
            final reverted = Map<String, dynamic>.from(m);
            reverted['content'] = originalContent;
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
      ref
          .read(pinnedMessagesProvider.notifier)
          .unpinMessage(channelId, messageId);
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
