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
  final _composerKey = GlobalKey<DmMessageComposerState>();

  String get _recipientHandle {
    final parts = widget.conversation.displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '@user';
    String handle = parts.length == 1
        ? parts.first
        : '${parts.first}_${parts.last}';
    handle = handle.replaceAll('@', '');
    return '@$handle';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DropTarget(
      onDragDone: (detail) {
        _composerKey.currentState?.addFiles(detail.files);
        setState(() => _isDragging = false);
      },
      onDragEntered: (detail) => setState(() => _isDragging = true),
      onDragExited: (detail) => setState(() => _isDragging = false),
      child: Container(
        color: colors.onPrimary,
        child: Stack(
          children: [
            Column(
              children: [
                _DmChatHeader(conversation: widget.conversation),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final historyState = ref.watch(
                        chatHistoryProvider(widget.conversation.channelId),
                      );
                      final messages = historyState.messages;

                      return NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (!historyState.isLoading &&
                              historyState.hasMore &&
                              scrollInfo.metrics.pixels >=
                                  scrollInfo.metrics.maxScrollExtent * 0.8) {
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
                                  final msgSenderId =
                                      (msg['user_id'] ?? msg['userId'] ?? '')
                                          .toString();
                                  final msgDate =
                                      DateTime.tryParse(
                                        msg['created_at']?.toString() ?? '',
                                      )?.toLocal() ??
                                      DateTime.now();

                                  // Determine if sender header should be shown.
                                  // In reversed list, index+1 is the message
                                  // ABOVE visually (older). Show header when
                                  // the sender changes or the day changes.
                                  bool showHeader = true;
                                  if (index < messages.length - 1) {
                                    final prevMsg = messages[index + 1];
                                    final prevSenderId =
                                        (prevMsg['user_id'] ??
                                                prevMsg['userId'] ??
                                                '')
                                            .toString();
                                    final prevDate =
                                        DateTime.tryParse(
                                          prevMsg['created_at']?.toString() ??
                                              '',
                                        )?.toLocal() ??
                                        DateTime.now();
                                    if (msgSenderId == prevSenderId &&
                                        _isSameDay(msgDate, prevDate)) {
                                      showHeader = false;
                                    }
                                  }

                                  // Determine if a day separator should be
                                  // shown above this message.
                                  bool showDaySeparator = false;
                                  if (index == messages.length - 1) {
                                    showDaySeparator = true;
                                  } else {
                                    final prevMsg = messages[index + 1];
                                    final prevDate =
                                        DateTime.tryParse(
                                          prevMsg['created_at']?.toString() ??
                                              '',
                                        )?.toLocal() ??
                                        DateTime.now();
                                    if (!_isSameDay(msgDate, prevDate)) {
                                      showDaySeparator = true;
                                    }
                                  }

                                  final content = parseHtmlToMarkdown(
                                    msg['content']?.toString() ?? '',
                                  );
                                  if (content.startsWith('<p>') &&
                                      content.contains(
                                        'started a conversation',
                                      )) {
                                    return const SizedBox.shrink();
                                  }

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (showDaySeparator)
                                        _DaySeparator(date: msgDate),
                                      _MessageBubble(
                                        message: msg,
                                        conversation: widget.conversation,
                                        channelId:
                                            widget.conversation.channelId,
                                        showHeader: showHeader,
                                      ),
                                    ],
                                  );
                                }, childCount: messages.length),
                              ),
                            ),
                            if (historyState.isLoading)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),
                            if (!historyState.hasMore)
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
                ),
              ],
            ),

            // ── Full-page call view ────────────────────────────────────────
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

            // ── Floating / PIP call view ───────────────────────────────────
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

            // ── Incoming call modal ────────────────────────────────────────
            const IncomingCallModal(),

            // ── Ringing overlay (caller side) ──────────────────────────────
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                              color: Colors.red,
                              onPressed: () => ref
                                  .read(activeCallProvider.notifier)
                                  .cancelCall(),
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

            // ── Drag-and-drop overlay ──────────────────────────────────────
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
                      child: const Text(
                        'Drop files to attach',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Date helpers
// ──────────────────────────────────────────────────────────────────────────────

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatDayLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDay = DateTime(date.year, date.month, date.day);

  if (messageDay == today) return 'Today';
  if (messageDay == today.subtract(const Duration(days: 1))) {
    return 'Yesterday';
  }

  final difference = today.difference(messageDay).inDays;
  if (difference < 7) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[date.weekday - 1];
  }

  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

// ──────────────────────────────────────────────────────────────────────────────
// Day separator
// ──────────────────────────────────────────────────────────────────────────────

class _DaySeparator extends StatelessWidget {
  final DateTime date;

  const _DaySeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = _formatDayLabel(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: colors.divider, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label,
              style: TextStyle(
                color: colors.textHint,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: colors.divider, height: 1)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Header
// ──────────────────────────────────────────────────────────────────────────────

class _DmChatHeader extends StatelessWidget {
  final DmConversation conversation;

  const _DmChatHeader({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: conversation.effectiveAvatarUrl != null
                ? Image.network(
                    conversation.effectiveAvatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Text(
                        participantInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      participantInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Text(
            conversation.displayName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          Consumer(
            builder: (context, ref, child) {
              return IconButton(
                icon: const Icon(Icons.notifications_active_outlined),
                tooltip: 'Test Notification (Delayed 5s)',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Notification will fire in 5 seconds. '
                        'Minimize the app now!',
                      ),
                    ),
                  );
                  Future.delayed(const Duration(seconds: 5), () {
                    ref
                        .read(notificationServiceProvider)
                        .handleIncomingMessage(
                          {
                            'user_id': conversation.participantId,
                            'content': 'Hello! This is a test DM notification.',
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
          const SizedBox(width: 12),
          Icon(Icons.more_vert, color: colors.textHint),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Message bubble
// ──────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends ConsumerStatefulWidget {
  final Map<String, dynamic> message;
  final DmConversation conversation;
  final String channelId;
  final bool showHeader;

  const _MessageBubble({
    required this.message,
    required this.conversation,
    required this.channelId,
    this.showHeader = true,
  });

  @override
  ConsumerState<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<_MessageBubble> {
  bool _isHovered = false;

  TextSpan _parseRichText(String text, TextStyle defaultStyle) {
    if (text.isEmpty) return TextSpan(style: defaultStyle, text: '');

    final boldRegex = RegExp(r'\*\*(.*?)\*\*', dotAll: true);
    final italicRegex = RegExp(r'(?<!\*)\*(.*?)\*(?!\*)', dotAll: true);
    final strikeRegex = RegExp(r'~~(.*?)~~', dotAll: true);
    final codeRegex = RegExp(r'`(.*?)`', dotAll: true);

    final combined = RegExp(
      [
        boldRegex,
        italicRegex,
        strikeRegex,
        codeRegex,
      ].map((r) => r.pattern).join('|'),
      dotAll: true,
    );

    final spans = <TextSpan>[];
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final history = ref.watch(chatHistoryProvider(widget.channelId));
    final isMe = history.isMyMessage(widget.message);
    final content = parseHtmlToMarkdown(
      widget.message['content'] as String? ?? '',
    );
    final createdAt =
        DateTime.tryParse(
          widget.message['created_at']?.toString() ?? '',
        )?.toLocal() ??
        DateTime.now();
    final status = widget.message['status'] as String?;
    final messageId = widget.message['id'] as String? ?? '';

    final hour = createdAt.hour > 12
        ? createdAt.hour - 12
        : (createdAt.hour == 0 ? 12 : createdAt.hour);
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final period = createdAt.hour >= 12 ? 'PM' : 'AM';
    final timeString = '$hour:$minute $period';

    // Use username from message if available, fall back to conversation name
    final senderName = isMe
        ? history.currentUserName
        : (widget.message['username'] as String? ??
              widget.conversation.displayName);
    final senderAvatarUrl = isMe
        ? history.currentUserAvatarUrl
        : (widget.message['avatar_url'] as String? ??
              widget.conversation.effectiveAvatarUrl);
    final senderInitial = senderName.isNotEmpty
        ? senderName[0].toUpperCase()
        : '?';

    final List<dynamic> media =
        (widget.message['media'] as List<dynamic>?) ?? [];

    final type = widget.message['type'] as String?;

    if (type == 'call' || type == 'call_log') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.call, color: colors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buzz Call',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    content.isNotEmpty ? content : 'Call ended',
                    style: TextStyle(color: colors.textHint, fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              timeString,
              style: TextStyle(color: colors.textHint, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // ── Content widgets (shared between header and grouped layout) ─────────
    final contentStyle = TextStyle(color: colors.textPrimary, fontSize: 14);

    final contentWidget = content.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 2),
            child: RichText(text: _parseRichText(content, contentStyle)),
          )
        : null;

    final attachmentWidget = media.isNotEmpty
        ? Padding(
            padding: EdgeInsets.only(top: content.isNotEmpty ? 6 : 2),
            child: _AttachmentBubbleList(media: media, isMe: false),
          )
        : null;

    final statusWidget = (isMe && status != null)
        ? Padding(
            padding: const EdgeInsets.only(top: 4),
            child: status == 'failed'
                ? Tooltip(
                    message:
                        (widget.message['error'] as String?) ??
                        'Failed to send message',
                    child: GestureDetector(
                      onTap: () => ref
                          .read(chatHistoryProvider(widget.channelId))
                          .retryMessage(messageId),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 13,
                            color: colors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Failed – Tap to retry',
                            style: TextStyle(
                              color: colors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Text(
                    status == 'sending' ? 'Sending...' : '',
                    style: TextStyle(color: colors.textHint, fontSize: 11),
                  ),
          )
        : null;

    final hoverActions = _isHovered
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.reply, size: 16),
                onPressed: () {},
                splashRadius: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Reply',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {},
                splashRadius: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Copy',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 16),
                onPressed: () {},
                splashRadius: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          )
        : const SizedBox.shrink();

    // ── Grouped message (no header) ───────────────────────────────────────
    if (!widget.showHeader) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          padding: const EdgeInsets.only(left: 42, bottom: 2, right: 8),
          color: _isHovered
              ? colors.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [?contentWidget, ?attachmentWidget, ?statusWidget],
                ),
              ),
              if (_isHovered) hoverActions,
            ],
          ),
        ),
      );
    }

    // ── Full message with header ──────────────────────────────────────────
    final avatar = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: senderAvatarUrl != null && senderAvatarUrl.isNotEmpty
          ? Image.network(
              senderAvatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  senderInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                senderInitial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.only(bottom: 4, top: 8, right: 8),
        color: _isHovered
            ? colors.primary.withValues(alpha: 0.05)
            : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        senderName,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeString,
                        style: TextStyle(color: colors.textHint, fontSize: 11),
                      ),
                    ],
                  ),
                  ?contentWidget,
                  ?attachmentWidget,
                  ?statusWidget,
                ],
              ),
            ),
            if (_isHovered) hoverActions,
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Attachment list
// ──────────────────────────────────────────────────────────────────────────────

class _AttachmentBubbleList extends StatelessWidget {
  final List<dynamic> media;
  final bool isMe;

  const _AttachmentBubbleList({required this.media, required this.isMe});

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
        width: 120,
        padding: const EdgeInsets.all(8),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isImage ? Icons.image_rounded : Icons.insert_drive_file_rounded,
              color: isMe ? colors.primary : colors.textPrimary,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              fileName,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
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
        // Try multiple field names the backend might use for the URL.
        final String fileLink = (item['file_link'] ??
                item['file_url'] ??
                item['url'] ??
                item['link'] ??
                '')
            .toString();

        // Derive extension from file_type, or fall back to the filename/url.
        final rawType = (item['file_type'] ?? '').toString().toLowerCase();
        final ext = rawType.isNotEmpty
            ? rawType
            : fileName.contains('.')
                ? fileName.split('.').last.toLowerCase()
                : fileLink.contains('.')
                    ? fileLink.split('.').last.split('?').first.toLowerCase()
                    : '';

        const imageExts = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'svg'};
        const audioExts = {'m4a', 'mp3', 'ogg', 'wav', 'aac', 'webm', 'opus'};

        final isImage = imageExts.contains(ext);
        final isAudio = audioExts.contains(ext);

        // ── Audio: render a playable VoiceNotePlayer ─────────────────────────
        if (isAudio && fileLink.isNotEmpty) {
          return SizedBox(
            width: 260,
            child: VoiceNotePlayer(audioSource: fileLink),
          );
        }

        // ── Image: render inline with network or local file support ──────────
        if (isImage && fileLink.isNotEmpty) {
          final isNetwork = fileLink.startsWith('http');
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _launchUrl(fileLink),
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
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: context.colors.primary,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              _buildGenericFile(
                                fileName,
                                fileLink,
                                isImage,
                                context,
                              ),
                        )
                      : Image.file(
                          File(fileLink),
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
            ),
          );
        }

        return _buildGenericFile(fileName, fileLink, isImage, context);
      }).toList(),
    );
  }
}
