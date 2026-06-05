import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class DmChatArea extends ConsumerStatefulWidget {
  final DmConversation conversation;

  const DmChatArea({super.key, required this.conversation});

  @override
  ConsumerState<DmChatArea> createState() => _DmChatAreaState();
}

class _DmChatAreaState extends ConsumerState<DmChatArea> {
  bool _isDragging = false;
  bool _showRightPanel = false;
  final _composerKey = GlobalKey<DmMessageComposerState>();
  final Map<String, GlobalKey> _messageKeys = {};
  String? _highlightedMessageId;
  String? _activeThreadId;
  Map<String, dynamic>? _activeThreadMessage;

  String get _recipientHandle {
    final parts = widget.conversation.displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '@user';
    if (parts.length == 1) return '@${parts.first}';
    return '@${parts.first}_${parts.last}';
  }

  void _scrollToMessage(String messageId) {
    final key = _messageKeys[messageId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        alignment: 0.5,
      );
      setState(() {
        _highlightedMessageId = messageId;
      });
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _highlightedMessageId = null;
          });
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message not loaded in visible history.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(channelProvider);
    final colors = context.colors;
    final isThreadActive = _activeThreadId != null;

    return DropTarget(
      onDragDone: (detail) {
        _composerKey.currentState?.addFiles(detail.files);
        setState(() => _isDragging = false);
      },
      onDragEntered: (detail) {
        setState(() => _isDragging = true);
      },
      onDragExited: (detail) {
        setState(() => _isDragging = false);
      },
      child: Container(
        color: colors.onPrimary,
        child: Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  if (isThreadActive)
                    _ThreadRepliesPanel(
                      channelId: widget.conversation.channelId,
                      threadId: _activeThreadId!,
                      originalMessage: _activeThreadMessage!,
                      conversation: widget.conversation,
                      onClose: () => setState(() {
                        _activeThreadId = null;
                        _activeThreadMessage = null;
                      }),
                    )
                  else
                    Column(
                      children: [
                        _DmChatHeader(
                          conversation: widget.conversation,
                          onToggleRightPanel: () {
                            setState(() {
                              _showRightPanel = !_showRightPanel;
                            });
                          },
                          showRightPanel: _showRightPanel,
                        ),
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final historyState = ref.watch(
                                chatHistoryProvider(
                                  widget.conversation.channelId,
                                ),
                              );
                              final messages = historyState.messages;

                              return NotificationListener<ScrollNotification>(
                                onNotification:
                                    (ScrollNotification scrollInfo) {
                                      if (!historyState.isLoading &&
                                          historyState.hasMore &&
                                          scrollInfo.metrics.pixels >=
                                              scrollInfo
                                                      .metrics
                                                      .maxScrollExtent *
                                                  0.8) {
                                        ref
                                            .read(
                                              chatHistoryProvider(
                                                widget.conversation.channelId,
                                              ),
                                            )
                                            .loadMore();
                                      }
                                      return false;
                                    },
                                child: CustomScrollView(
                                  reverse: true,
                                  slivers: [
                                    SliverPadding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      sliver: SliverList(
                                        delegate: SliverChildBuilderDelegate((
                                          context,
                                          index,
                                        ) {
                                          final msg = messages[index];
                                          final messageId =
                                              msg['id'] as String? ?? '';
                                          final key = _messageKeys.putIfAbsent(
                                            messageId,
                                            () => GlobalKey(),
                                          );

                                          return _MessageBubble(
                                            key: key,
                                            message: msg,
                                            conversation: widget.conversation,
                                            channelId:
                                                widget.conversation.channelId,
                                            isHighlighted:
                                                _highlightedMessageId ==
                                                messageId,
                                            onReplyInThread: (message) {
                                              setState(() {
                                                _activeThreadId =
                                                    message['id'] as String?;
                                                _activeThreadMessage = message;
                                              });
                                            },
                                          );
                                        }, childCount: messages.length),
                                      ),
                                    ),
                                    if (historyState.isLoading)
                                      const SliverToBoxAdapter(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                      ),
                                    if (!historyState.hasMore)
                                      if (widget.conversation.channelType == 'dm')
                                        SliverToBoxAdapter(
                                          child: DmProfileCard(
                                            conversation: widget.conversation,
                                          ),
                                        ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        DmMessageComposer(
                          key: _composerKey,
                          recipientName: _recipientHandle,
                          channelId: widget.conversation.channelId,
                          participants: widget.conversation.participants,
                          isMember:
                              widget.conversation.channelType != 'channel' ||
                              ref
                                  .watch(channelProvider)
                                  .channels
                                  .any(
                                    (c) =>
                                        c.id == widget.conversation.channelId,
                                  ),
                        ),
                      ],
                    ),

                  Consumer(
                    builder: (context, ref, child) {
                      final activeCall = ref.watch(activeCallProvider);
                      if (activeCall.state.status == CallStatus.active &&
                          activeCall.state.isFullPage) {
                        return const Positioned.fill(child: BuzzMeetingView());
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  Consumer(
                    builder: (context, ref, child) {
                      final activeCall = ref.watch(activeCallProvider);
                      if (activeCall.state.status == CallStatus.active &&
                          !activeCall.state.isFullPage) {
                        return const BuzzMeetingView();
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const IncomingCallModal(),

                  Consumer(
                    builder: (context, ref, child) {
                      final activeCall = ref.watch(activeCallProvider);
                      if (activeCall.state.status == CallStatus.calling) {
                        return Positioned(
                          top: 24,
                          right: 24,
                          child: Material(
                            color: Colors.transparent,
                            elevation: 8,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 320,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.divider),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Calling...',
                                          style: TextStyle(
                                            color: colors.textHint,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          activeCall.state.remoteUserName ??
                                              'Unknown',
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.call_end),
                                    color: colors.error,
                                    onPressed: () {
                                      ref
                                          .read(activeCallProvider.notifier)
                                          .cancelCall();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  if (_isDragging)
                    Positioned.fill(
                      child: Container(
                        color: colors.primary.withValues(alpha: 0.2),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Drop files to attach',
                              style: context.textTheme.titleMedium?.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_showRightPanel && !isThreadActive)
              Container(
                width: 360,
                decoration: BoxDecoration(
                  color: colors.background,
                  border: Border(left: BorderSide(color: colors.divider)),
                ),
                child: _PinnedMessagesPanel(
                  channelId: widget.conversation.channelId,
                  onClose: () => setState(() => _showRightPanel = false),
                  onCardTap: _scrollToMessage,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DmChatHeader extends StatelessWidget {
  final DmConversation conversation;
  final VoidCallback onToggleRightPanel;
  final bool showRightPanel;

  const _DmChatHeader({
    required this.conversation,
    required this.onToggleRightPanel,
    required this.showRightPanel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isChannel =
        conversation.channelType == 'channel' ||
        conversation.channelType == 'group_dm';

    final participantInitial = conversation.displayName.trim().isEmpty
        ? '?'
        : conversation.displayName.trim()[0].toUpperCase();

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          if (isChannel)
            Text(
              '# ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            )
          else
            CircleAvatar(
              radius: 20,
              backgroundColor: colors.primary,
              backgroundImage: conversation.effectiveAvatarUrl != null
                  ? NetworkImage(conversation.effectiveAvatarUrl!)
                  : null,
              child: conversation.effectiveAvatarUrl == null
                  ? Text(
                      participantInitial,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          if (!isChannel) const SizedBox(width: 12),
          Text(
            isChannel
                ? conversation.displayName.replaceFirst('#', '').trim()
                : conversation.displayName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          if (isChannel) ...[
            Consumer(
              builder: (context, ref, child) {
                return OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(activeCallProvider.notifier)
                        .initiateCall(
                          remoteUserId: conversation.participantId,
                          remoteUserName: conversation.displayName,
                          channelId: conversation.channelId,
                          remoteAvatarUrl: conversation.effectiveAvatarUrl,
                        );
                  },
                  icon: const Icon(Icons.headphones, size: 16),
                  label: const Text('Start Buzz'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.divider),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    minimumSize: const Size(0, 32),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 24, color: colors.divider),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.person_outline, color: colors.primary),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) =>
                      ChannelDetailsModal(conversation: conversation),
                );
              },
            ),
            Consumer(
              builder: (context, ref, child) {
                return PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colors.textHint),
                  onSelected: (value) async {
                    if (value == 'details') {
                      showDialog<void>(
                        context: context,
                        builder: (_) =>
                            ChannelDetailsModal(conversation: conversation),
                      );
                    } else if (value == 'notifications') {
                      _showNotificationSettingsDialog(
                        context,
                        ref,
                        conversation.channelId,
                        conversation.displayName.replaceFirst('#', ''),
                      );
                    } else if (value == 'leave') {
                      _showLeaveChannelConfirmDialog(
                        context,
                        ref,
                        conversation.channelId,
                        conversation.displayName.replaceFirst('#', ''),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Text(
                        'Open channel details',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'notifications',
                      child: Text(
                        'Notification Settings',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'search',
                      child: Text(
                        'Search in channel',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'leave',
                      child: Text(
                        'Leave channel',
                        style: TextStyle(fontSize: 13, color: Colors.red),
                      ),
                    ),
                  ],
                );
              },
            ),
          ] else ...[
            Consumer(
              builder: (context, ref, child) {
                return IconButton(
                  icon: const Icon(Icons.notifications_active_outlined),
                  tooltip: 'Test Notification (Delayed 5s)',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification will fire in 5 seconds.'),
                      ),
                    );
                    Future.delayed(const Duration(seconds: 5), () {
                      ref
                          .read(notificationServiceProvider)
                          .handleIncomingMessage(
                            {
                              'user_id': conversation.participantId,
                              'content':
                                  'Hello! This is a test DM notification.',
                            },
                            conversation.channelId,
                            conversation.displayName,
                            forceShow: true,
                          );
                    });
                  },
                );
              },
            ),
            const SizedBox(width: 8),
            Consumer(
              builder: (context, ref, child) {
                return InkWell(
                  onTap: () {
                    ref
                        .read(activeCallProvider.notifier)
                        .initiateCall(
                          remoteUserId: conversation.participantId,
                          remoteUserName: conversation.displayName,
                          channelId: conversation.channelId,
                          remoteAvatarUrl: conversation.effectiveAvatarUrl,
                        );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.divider),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.headphones_outlined,
                      size: 18,
                      color: colors.textPrimary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                showRightPanel ? Icons.push_pin : Icons.push_pin_outlined,
                color: showRightPanel ? colors.primary : colors.textHint,
              ),
              tooltip: 'Pinned Messages',
              onPressed: onToggleRightPanel,
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageBubble extends ConsumerStatefulWidget {
  final Map<String, dynamic> message;
  final DmConversation conversation;
  final String channelId;
  final bool isHighlighted;
  final void Function(Map<String, dynamic> message)? onReplyInThread;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.conversation,
    required this.channelId,
    required this.isHighlighted,
    this.onReplyInThread,
  });

  @override
  ConsumerState<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<_MessageBubble> {
  bool _isHovering = false;

  bool _isAudioMessage(Map<String, dynamic> msg) {
    final content = (msg['content'] ?? '').toString();
    if (content == '[Voice Note Attached]') return true;

    final media = msg['media'] as List<dynamic>? ?? const [];
    for (var m in media) {
      if (m is Map) {
        final name = (m['file_name'] ?? m['name'] ?? '')
            .toString()
            .toLowerCase();
        final ext = name.split('.').last.toLowerCase();
        if ([
              'm4a',
              'mp3',
              'wav',
              'aac',
              'ogg',
              'caf',
              'opus',
              'mp4',
              'webm',
            ].contains(ext) ||
            name.contains('voice_note')) {
          return true;
        }
      }
    }
    return false;
  }

  String _getAudioSource(Map<String, dynamic> msg) {
    if (msg['audio_source'] != null) return msg['audio_source'].toString();
    if (msg['file_link'] != null &&
        msg['file_link'].toString().endsWith('.m4a')) {
      return msg['file_link'].toString();
    }

    final media = msg['media'] as List<dynamic>? ?? const [];
    for (var m in media) {
      if (m is Map) {
        final name = (m['file_name'] ?? m['name'] ?? '')
            .toString()
            .toLowerCase();
        final ext = name.split('.').last.toLowerCase();
        if ([
              'm4a',
              'mp3',
              'wav',
              'aac',
              'ogg',
              'caf',
              'opus',
              'mp4',
              'webm',
            ].contains(ext) ||
            name.contains('voice_note')) {
          return (m['file_link'] ?? m['path'] ?? '').toString();
        }
      }
    }
    return '';
  }

  void _handleChannelTap(String channelName) {
    final channels = ref.read(channelProvider).channels;
    final found = channels.firstWhere(
      (c) => c.name.toLowerCase() == channelName.toLowerCase(),
      orElse: () => const Channel(
        id: '',
        name: '',
        description: '',
        organisationId: '',
        ownerId: '',
      ),
    );
    if (found.id.isNotEmpty) {
      ref.read(homeSidebarProvider.notifier).setType(HomeSidebarType.home);
      ref.read(activeChatProvider.notifier).selectChannel(found.id);
    }
  }

  void _handleMentionTap(String username) {
    final teamMembers = ref.read(userProfileNotifierProvider).teamMembers;
    final found = teamMembers.firstWhere(
      (m) => (m.name ?? '').toLowerCase() == username.toLowerCase(),
      orElse: () => const TeamMember(
        id: '',
        email: '',
        role: '',
        dateJoined: '',
        status: TeamMemberStatus.inactive,
      ),
    );
    if (found.id.isNotEmpty) {
      final conversations = ref.read(dmListProvider).value ?? [];
      final existing = conversations.firstWhere(
        (c) => c.participantId == found.id,
        orElse: () => DmConversation(
          channelId: found.id,
          username: found.name ?? username,
          participantId: found.id,
          previewMessage: '',
          unreadCount: 0,
        ),
      );
      ref.read(homeSidebarProvider.notifier).setType(HomeSidebarType.dms);
      ref.read(selectedDmProvider.notifier).select(existing);
      ref
          .read(activeChatProvider.notifier)
          .selectDirectMessage(existing.channelId);
    }
  }

  TextSpan _parseRichText(String text, TextStyle defaultStyle) {
    if (text.isEmpty) return TextSpan(style: defaultStyle, text: '');

    final colors = context.colors;
    final boldRegex = RegExp(r'\*\*(.*?)\*\*', dotAll: true);
    final italicRegex = RegExp(r'\*(?!\*)(.*?)\*', dotAll: true);
    final strikeRegex = RegExp(r'~~(.*?)~~', dotAll: true);
    final codeRegex = RegExp(r'`(.*?)`', dotAll: true);
    final mentionRegex = RegExp(r'@\w+');
    final channelRegex = RegExp(r'#[\w-]+');

    final combined = RegExp(
      r'(\*\*.*?\*\*)|(\*(?!\*).*?\*)|(~~.*?~~)|(`.*?`)|(@\w+)|(#[\w-]+)',
      dotAll: true,
    );

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in combined.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: defaultStyle,
          ),
        );
      }

      final raw = match.group(0)!;
      if (boldRegex.hasMatch(raw)) {
        final inner =
            match.group(1) ?? boldRegex.firstMatch(raw)?.group(1) ?? raw;
        spans.add(
          TextSpan(
            text: inner,
            style: defaultStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      } else if (strikeRegex.hasMatch(raw)) {
        final inner = strikeRegex.firstMatch(raw)?.group(1) ?? raw;
        spans.add(
          TextSpan(
            text: inner,
            style: defaultStyle.copyWith(
              decoration: TextDecoration.lineThrough,
            ),
          ),
        );
      } else if (codeRegex.hasMatch(raw)) {
        final inner = codeRegex.firstMatch(raw)?.group(1) ?? raw;
        spans.add(
          TextSpan(
            text: inner,
            style: defaultStyle.copyWith(
              fontFamily: 'monospace',
              backgroundColor: const Color(0x1A6458F5),
              color: const Color(0xFF6458F5),
            ),
          ),
        );
      } else if (italicRegex.hasMatch(raw)) {
        final inner = italicRegex.firstMatch(raw)?.group(1) ?? raw;
        spans.add(
          TextSpan(
            text: inner,
            style: defaultStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      } else if (mentionRegex.hasMatch(raw)) {
        final username = raw.substring(1);
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => _handleMentionTap(username),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  raw,
                  style: defaultStyle.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      } else if (channelRegex.hasMatch(raw)) {
        final channelName = raw.substring(1);
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => _handleChannelTap(channelName),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  raw,
                  style: defaultStyle.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: raw, style: defaultStyle));
      }
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: defaultStyle));
    }

    return TextSpan(style: defaultStyle, children: spans);
  }

  void _showLightbox(BuildContext context, String imageUrl) {
    final colors = context.colors;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                child: imageUrl.startsWith('http')
                    ? Image.network(imageUrl, fit: BoxFit.contain)
                    : Image.asset(imageUrl, fit: BoxFit.contain),
              ),
              Positioned(
                top: 24,
                right: 24,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: Icon(Icons.close, color: colors.onPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineEditor(
    BuildContext context,
    ChatHistoryNotifier history,
    String messageId,
    String initialText,
    AppPalette colors,
  ) {
    final controller = TextEditingController(text: initialText);
    return Container(
      width: 300,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: controller,
            maxLines: null,
            autofocus: true,
            style: TextStyle(color: colors.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: history.cancelEditing,
                child: const Text('Cancel', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: () {
                  history.saveEdit(messageId, controller.text);
                },
                child: const Text('Save', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final history = ref.watch(chatHistoryProvider(widget.channelId));
    final isMe = history.isMyMessage(widget.message);
    final content = widget.message['content'] as String? ?? '';
    final createdAt = DateFormatter.parseUtcString(
      widget.message['created_at']?.toString() ?? '',
    );
    final status = widget.message['status'] as String?;
    final messageId = widget.message['id'] as String? ?? '';

    final isEditable =
        isMe && DateTime.now().difference(createdAt).inMinutes < 10;

    final timeString = DateFormatter.formatTime12h(createdAt);

    String? fallbackName = widget.message['sender_name']?.toString() ??
        widget.message['username']?.toString() ??
        widget.message['user_name']?.toString();

    if (fallbackName == null && widget.message['sender'] is Map<String, dynamic>) {
      final senderMap = widget.message['sender'] as Map<String, dynamic>;
      fallbackName = senderMap['username']?.toString() ??
          senderMap['name']?.toString() ??
          senderMap['user_name']?.toString();
    }

    if (fallbackName == null) {
      final userId = widget.message['user_id']?.toString() ?? 
                     widget.message['userId']?.toString() ?? 
                     widget.message['sender_id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        try {
          final participant = widget.conversation.participants.firstWhere(
            (p) => p.userId == userId,
          );
          if (participant.username.isNotEmpty) {
            fallbackName = participant.username;
          } else if (participant.email.isNotEmpty) {
            fallbackName = participant.email.split('@').first;
          }
        } catch (_) {}
      }
    }

    final String senderName = isMe
        ? history.currentUserName
        : (fallbackName ?? widget.conversation.displayName).toString();

    final String? senderAvatarUrl = isMe
        ? history.currentUserAvatarUrl
        : (widget.message['avatar_url']?.toString() ??
              widget.message['sender_avatar_url']?.toString() ??
              widget.conversation.effectiveAvatarUrl);

    final senderInitial = senderName.isNotEmpty
        ? senderName[0].toUpperCase()
        : '?';

    final List<dynamic> media =
        (widget.message['media'] as List<dynamic>?) ?? [];
    final Map<String, dynamic> reactionsMap =
        widget.message['reactions'] as Map<String, dynamic>? ?? {};

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: widget.isHighlighted
            ? colors.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    InkWell(
                      onTap: () {
                        final teamMembers = ref
                            .read(userProfileNotifierProvider)
                            .teamMembers;
                        final found = teamMembers.firstWhere(
                          (m) =>
                              (m.name ?? '').toLowerCase() ==
                              senderName.toLowerCase(),
                          orElse: () => TeamMember(
                            id: widget.message['sender_id']?.toString() ?? '',
                            email: '',
                            role: 'Member',
                            dateJoined: '',
                            status: TeamMemberStatus.active,
                            name: senderName,
                            avatarUrl: senderAvatarUrl,
                          ),
                        );
                        ref.read(personalProfilePanelProvider.notifier).state =
                            false;
                        ref.read(profileDetailsPanelProvider.notifier).state =
                            found;
                      },
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: colors.primary,
                        backgroundImage:
                            senderAvatarUrl != null &&
                                senderAvatarUrl.isNotEmpty
                            ? NetworkImage(senderAvatarUrl)
                            : null,
                        child:
                            senderAvatarUrl == null || senderAvatarUrl.isEmpty
                            ? Text(
                                senderInitial,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: colors.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () {
                                  final teamMembers = ref
                                      .read(userProfileNotifierProvider)
                                      .teamMembers;
                                  final found = teamMembers.firstWhere(
                                    (m) =>
                                        (m.name ?? '').toLowerCase() ==
                                        senderName.toLowerCase(),
                                    orElse: () => TeamMember(
                                      id: widget.message['sender_id']?.toString() ?? '',
                                      email: '',
                                      role: 'Member',
                                      dateJoined: '',
                                      status: TeamMemberStatus.active,
                                      name: senderName,
                                      avatarUrl: senderAvatarUrl,
                                    ),
                                  );
                                  ref.read(personalProfilePanelProvider.notifier).state = false;
                                  ref.read(profileDetailsPanelProvider.notifier).state = found;
                                },
                                child: Text(
                                  senderName,
                                  style: TextStyle(
                                    color: isMe
                                        ? colors.primary
                                        : const Color(0xFF00BFA5), // Teal accent for receiving
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeString,
                                style: TextStyle(
                                  color: colors.textHint,
                                  fontSize: 11,
                                ),
                              ),
                              if (widget.message['is_edited'] == true ||
                                  widget.message['edited'] == true) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(edited)',
                                  style: TextStyle(
                                    color: colors.textHint,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (history.editingMessageId == messageId)
                          _buildInlineEditor(
                            context,
                            history,
                            messageId,
                            content,
                            colors,
                          )
                        else if (_isAudioMessage(widget.message))
                          VoiceNotePlayer(
                            audioSource: _getAudioSource(widget.message),
                          )
                        else if (content.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? colors.primary
                                  : colors.onPrimary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: RichText(
                              text: _parseRichText(
                                content,
                                context.textTheme.bodyMedium?.copyWith(
                                      color: isMe
                                          ? colors.onPrimary
                                          : colors.textPrimary,
                                    ) ??
                                    const TextStyle(),
                              ),
                            ),
                          ),
                        if (media.isNotEmpty)
                          (() {
                            final filteredMedia = media.where((m) {
                              final name = (m['file_name'] ?? m['name'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              final ext = name.split('.').last.toLowerCase();
                              final isAudio =
                                  [
                                    'm4a',
                                    'mp3',
                                    'wav',
                                    'aac',
                                    'ogg',
                                    'caf',
                                    'opus',
                                    'mp4',
                                    'webm',
                                  ].contains(ext) ||
                                  name.contains('voice_note');
                              return !isAudio;
                            }).toList();
                            if (filteredMedia.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: EdgeInsets.only(
                                top: content.isNotEmpty ? 8 : 0,
                              ),
                              child: _AttachmentBubbleList(
                                media: filteredMedia,
                                isMe: isMe,
                                onImageTap: (url) =>
                                    _showLightbox(context, url),
                              ),
                            );
                          })(),
                        if (reactionsMap.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 4,
                              children: reactionsMap.entries.map((entry) {
                                final emoji = entry.key;
                                final userIds = List<String>.from(
                                  entry.value as List<dynamic>? ?? [],
                                );
                                final currentUserId =
                                    ref.read(authNotifierProvider).user?.id ??
                                    '';
                                final hasReacted = userIds.contains(
                                  currentUserId,
                                );

                                return Tooltip(
                                  message:
                                      'Reacted by ${userIds.length} member(s)',
                                  child: InkWell(
                                    onTap: () {
                                      history.toggleReaction(
                                        messageId,
                                        emoji,
                                        currentUserId,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: hasReacted
                                            ? colors.primary.withValues(
                                                alpha: 0.15,
                                              )
                                            : colors.onPrimary.withValues(
                                                alpha: 0.05,
                                              ),
                                        border: Border.all(
                                          color: hasReacted
                                              ? colors.primary
                                              : colors.divider,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            emoji,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${userIds.length}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: hasReacted
                                                  ? colors.primary
                                                  : colors.textSecondary,
                                              fontWeight: hasReacted
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        if (isMe && status != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: status.toString().startsWith('failed')
                                ? GestureDetector(
                                    onTap: () {
                                      ref
                                          .read(
                                            chatHistoryProvider(
                                              widget.channelId,
                                            ),
                                          )
                                          .retryMessage(messageId);
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 13,
                                          color: colors.error,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            status == 'failed'
                                                ? 'Failed – Tap to retry'
                                                : status.toString(),
                                            style: TextStyle(
                                              color: colors.error,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Text(
                                    status == 'sending' ? 'Sending...' : '',
                                    style: TextStyle(
                                      color: colors.textHint,
                                      fontSize: 11,
                                    ),
                                  ),
                          ),
                        if ((widget.message['thread_count'] as int? ??
                                widget.message['reply_count'] as int? ??
                                0) >
                            0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: InkWell(
                              onTap: () =>
                                  widget.onReplyInThread?.call(widget.message),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: colors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.forum_outlined,
                                      size: 14,
                                      color: colors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${widget.message['thread_count'] ?? widget.message['reply_count']} ${widget.message['thread_count'] == 1 || widget.message['reply_count'] == 1 ? "reply" : "replies"}',
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 14,
                                      color: colors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isHovering && history.editingMessageId != messageId)
              Positioned(
                top: -12,
                right: isMe ? null : 16,
                left: isMe ? 16 : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.add_reaction_outlined,
                          size: 18,
                          color: colors.textHint,
                        ),
                        onSelected: (emoji) {
                          final currentUserId =
                              ref.read(authNotifierProvider).user?.id ?? '';
                          history.toggleReaction(
                            messageId,
                            emoji,
                            currentUserId,
                          );
                        },
                        offset: const Offset(0, 30),
                        padding: EdgeInsets.zero,
                        tooltip: 'Add reaction',
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: '👍', child: Text('👍')),
                          PopupMenuItem(value: '❤️', child: Text('❤️')),
                          PopupMenuItem(value: '😂', child: Text('😂')),
                          PopupMenuItem(value: '🎉', child: Text('🎉')),
                          PopupMenuItem(value: '👎', child: Text('👎')),
                        ],
                      ),
                      if (widget.onReplyInThread != null)
                        IconButton(
                          icon: Icon(
                            Icons.chat_bubble_outline,
                            size: 18,
                            color: colors.textHint,
                          ),
                          tooltip: 'Reply in thread',
                          onPressed: () =>
                              widget.onReplyInThread?.call(widget.message),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                        ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 18,
                          color: colors.textHint,
                        ),
                        tooltip: 'More options',
                        offset: const Offset(0, 30),
                        padding: EdgeInsets.zero,
                        color: colors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: colors.divider),
                        ),
                        onSelected: (value) async {
                          switch (value) {
                            case 'reply':
                              widget.onReplyInThread?.call(widget.message);
                              break;
                            case 'pin':
                              final isPinned =
                                  ref
                                      .read(
                                        pinnedMessagesProvider,
                                      )[widget.channelId]
                                      ?.any((m) => m.id == messageId) ==
                                  true;
                              if (isPinned) {
                                ref
                                    .read(pinnedMessagesProvider.notifier)
                                    .unpinMessage(widget.channelId, messageId);
                              } else {
                                ref
                                    .read(pinnedMessagesProvider.notifier)
                                    .pinMessage(
                                      widget.channelId,
                                      PinnedMessage(
                                        id: messageId,
                                        content: content,
                                        senderName: senderName,
                                        pinnedBy:
                                            ref
                                                .read(authNotifierProvider)
                                                .user
                                                ?.fullname ??
                                            'You',
                                        pinnedAt: DateTime.now(),
                                        channelId: widget.channelId,
                                      ),
                                    );
                              }
                              break;
                            case 'edit':
                              history.startEditing(messageId);
                              break;
                            case 'delete':
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Message'),
                                  content: const Text(
                                    'Are you sure you want to delete this message? This cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colors.error,
                                        foregroundColor: colors.onPrimary,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                history.deleteMessage(messageId);
                              }
                              break;
                            case 'unread':
                            case 'copy':
                            case 'forward':
                            case 'save':
                              AppToastService.show(
                                context,
                                type: AppToastType.info,
                                message: 'Feature coming soon',
                              );
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'reply',
                            height: 40,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.turn_left,
                                  size: 18,
                                  color: colors.textPrimary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Reply in thread',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'unread',
                            height: 40,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.mark_email_unread_outlined,
                                  size: 18,
                                  color: colors.textPrimary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Mark unread',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'copy',
                            height: 40,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.link,
                                  size: 18,
                                  color: colors.textPrimary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Copy link',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'pin',
                            height: 40,
                            child: Row(
                              children: [
                                Icon(
                                  ref
                                              .watch(
                                                pinnedMessagesProvider,
                                              )[widget.channelId]
                                              ?.any((m) => m.id == messageId) ==
                                          true
                                      ? Icons.push_pin
                                      : Icons.push_pin_outlined,
                                  size: 18,
                                  color: colors.textPrimary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Pin to this conversation',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'forward',
                            height: 40,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.forward_outlined,
                                  size: 18,
                                  color: colors.textPrimary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Forward message',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'save',
                            height: 40,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bookmark_border,
                                  size: 18,
                                  color: colors.textPrimary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Save for later',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isMe && isEditable) ...[
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'edit',
                              height: 40,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: colors.textPrimary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Edit message',
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              height: 40,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: colors.error,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Delete message',
                                    style: TextStyle(
                                      color: colors.error,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentBubbleList extends StatelessWidget {
  final List<dynamic> media;
  final bool isMe;
  final ValueChanged<String> onImageTap;

  const _AttachmentBubbleList({
    required this.media,
    required this.isMe,
    required this.onImageTap,
  });

  void _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildGenericFile(
    String fileName,
    String fileLink,
    bool isImage,
    BuildContext context,
  ) {
    final colors = context.colors;
    return GestureDetector(
      onTap: fileLink.isNotEmpty ? () => _launchUrl(fileLink) : null,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? colors.primary.withValues(alpha: 0.15)
              : colors.onPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isMe
                ? colors.primary.withValues(alpha: 0.3)
                : colors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isImage ? Icons.image_rounded : Icons.insert_drive_file_rounded,
              color: isMe ? colors.primary : colors.textPrimary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '1.2 MB',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.download_rounded,
                color: colors.primary,
                size: 18,
              ),
              onPressed: fileLink.isNotEmpty
                  ? () => _launchUrl(fileLink)
                  : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
      children: media.map((item) {
        final String fileName = (item['file_name'] ?? 'Attachment').toString();
        final String fileLink = (item['file_link'] ?? '').toString();
        final isImage = [
          'png',
          'jpg',
          'jpeg',
          'gif',
          'webp',
        ].contains((item['file_type'] ?? '').toString().toLowerCase());

        if (isImage && fileLink.isNotEmpty) {
          final isNetwork = fileLink.startsWith('http');

          return GestureDetector(
            onTap: () => onImageTap(fileLink),
            child: Container(
              width: 250,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.divider),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isNetwork
                    ? Image.network(
                        fileLink,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildGenericFile(
                              fileName,
                              fileLink,
                              isImage,
                              context,
                            ),
                      )
                    : (fileLink.startsWith('/') ||
                          fileLink.contains(':/') ||
                          fileLink.contains(':\\'))
                    ? Image.file(
                        File(fileLink),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildGenericFile(
                              fileName,
                              fileLink,
                              isImage,
                              context,
                            ),
                      )
                    : Image.asset(
                        fileLink,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildGenericFile(
                              fileName,
                              fileLink,
                              isImage,
                              context,
                            ),
                      ),
              ),
            ),
          );
        }

        return _buildGenericFile(fileName, fileLink, isImage, context);
      }).toList(),
    );
  }
}

class _PinnedMessagesPanel extends ConsumerWidget {
  final String channelId;
  final VoidCallback onClose;
  final ValueChanged<String> onCardTap;

  const _PinnedMessagesPanel({
    required this.channelId,
    required this.onClose,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final pinnedMap = ref.watch(pinnedMessagesProvider);
    final pinnedList = pinnedMap[channelId] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Pinned Messages (${pinnedList.length})',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: colors.textHint),
                onPressed: onClose,
              ),
            ],
          ),
        ),
        Expanded(
          child: pinnedList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.push_pin_outlined,
                        size: 48,
                        color: colors.textHint,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No pinned messages',
                        style: TextStyle(
                          color: colors.textHint,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pinnedList.length,
                  itemBuilder: (context, index) {
                    final msg = pinnedList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: colors.onPrimary.withValues(alpha: 0.05),
                      child: InkWell(
                        onTap: () => onCardTap(msg.id),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Pinned by ${msg.pinnedBy}',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 14),
                                    onPressed: () {
                                      ref
                                          .read(pinnedMessagesProvider.notifier)
                                          .unpinMessage(channelId, msg.id);
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                msg.content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

void _showNotificationSettingsDialog(
  BuildContext context,
  WidgetRef ref,
  String channelId,
  String channelName,
) {
  showDialog<void>(
    context: context,
    builder: (context) {
      final settings = ref.watch(notificationSettingsProvider);
      bool isMuted = settings.isChannelMuted(channelId);
      int notifyFor = 0;
      bool notifyReplies = true;

      return StatefulBuilder(
        builder: (context, setState) {
          final colors = context.colors;
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: 450,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications for #$channelName',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Send a notification for',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Radio<int>(
                      value: 0,
                      // ignore: deprecated_member_use
                      groupValue: notifyFor,
                      // ignore: deprecated_member_use
                      onChanged: (val) => setState(() => notifyFor = val!),
                      activeColor: colors.primary,
                    ),
                    title: const Text('All new messages'),
                    onTap: () => setState(() => notifyFor = 0),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Radio<int>(
                      value: 1,
                      // ignore: deprecated_member_use
                      groupValue: notifyFor,
                      // ignore: deprecated_member_use
                      onChanged: (val) => setState(() => notifyFor = val!),
                      activeColor: colors.primary,
                    ),
                    title: const Text('Mentions'),
                    onTap: () => setState(() => notifyFor = 1),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Radio<int>(
                      value: 2,
                      // ignore: deprecated_member_use
                      groupValue: notifyFor,
                      // ignore: deprecated_member_use
                      onChanged: (val) => setState(() => notifyFor = val!),
                      activeColor: colors.primary,
                    ),
                    title: const Text('Channels'),
                    onTap: () => setState(() => notifyFor = 2),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: notifyReplies,
                      // ignore: deprecated_member_use
                      onChanged: (val) =>
                          setState(() => notifyReplies = val ?? true),
                      activeColor: colors.primary,
                    ),
                    title: const Text(
                      'Get notified about all thread replies in this channel',
                    ),
                    onTap: () => setState(() => notifyReplies = !notifyReplies),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: isMuted,
                      // ignore: deprecated_member_use
                      onChanged: (val) =>
                          setState(() => isMuted = val ?? false),
                      activeColor: colors.primary,
                    ),
                    title: const Text('Mute channel'),
                    onTap: () => setState(() => isMuted = !isMuted),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: colors.textPrimary.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                      children: [
                        const TextSpan(
                          text:
                              'Note: You can set notification keywords and change your workspace-wide settings in your ',
                        ),
                        TextSpan(
                          text: 'settings',
                          style: TextStyle(
                            color: colors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: colors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (isMuted != settings.isChannelMuted(channelId)) {
                            ref
                                .read(notificationSettingsProvider.notifier)
                                .muteChannel(channelId);
                          }
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Save changes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

void _showLeaveChannelConfirmDialog(
  BuildContext context,
  WidgetRef ref,
  String channelId,
  String channelName,
) async {
  final colors = context.colors;
  final channelState = ref.read(channelProvider);
  final channel = channelState.channels.firstWhere((c) => c.id == channelId);
  final currentUser = ref.read(authNotifierProvider).user;

  if (channel.ownerId == currentUser?.id && channel.membersCount <= 1) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cannot Leave Channel'),
        content: const Text(
          'You are the last admin of this channel. Please assign a new admin before leaving.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Leave Channel'),
      content: Text('Are you sure you want to leave #$channelName?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onPrimary,
          ),
          child: const Text('Leave'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    final success = await ref
        .read(channelProvider.notifier)
        .leaveChannel(channelId);
    if (success && context.mounted) {
      ref.read(activeChatProvider.notifier).selectChannel('general');
      AppToastService.show(
        context,
        type: AppToastType.success,
        message: 'You left #$channelName.',
      );
    }
  }
}

class _ThreadRepliesPanel extends ConsumerWidget {
  final String channelId;
  final String threadId;
  final Map<String, dynamic> originalMessage;
  final DmConversation conversation;
  final VoidCallback onClose;

  const _ThreadRepliesPanel({
    required this.channelId,
    required this.threadId,
    required this.originalMessage,
    required this.conversation,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final threadHistory = ref.watch(
      chatHistoryProvider('$channelId:$threadId'),
    );
    final replies = threadHistory.messages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.divider)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                onPressed: onClose,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Thread',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      conversation.displayName,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textHint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Scrollable Replies List
        Expanded(
          child: CustomScrollView(
            reverse: true,
            slivers: [
              // Replies List
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final msg = replies[index];
                    return _MessageBubble(
                      message: msg,
                      conversation: conversation,
                      channelId: '$channelId:$threadId',
                      isHighlighted: false,
                      onReplyInThread: null,
                    );
                  }, childCount: replies.length),
                ),
              ),

              // Separator / Reply count
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${replies.length} ${replies.length == 1 ? "reply" : "replies"}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.textHint,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Divider(color: colors.divider)),
                    ],
                  ),
                ),
              ),

              // Original Message
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.onPrimary.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.divider.withValues(alpha: 0.5),
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6, left: 4),
                          child: Text(
                            'Original Message',
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _MessageBubble(
                          message: originalMessage,
                          conversation: conversation,
                          channelId: channelId,
                          isHighlighted: false,
                          onReplyInThread: null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (threadHistory.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),

        // Composer at the bottom
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.divider)),
            color: colors.background,
          ),
          child: DmMessageComposer(
            recipientName: 'Reply...',
            channelId: '$channelId:$threadId',
            participants: conversation.participants,
          ),
        ),
      ],
    );
  }
}
