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
  final List<XFile> _pendingFiles = [];

  void _addFiles(List<XFile> files) {
    setState(() {
      _pendingFiles.addAll(files);
    });
  }

  void _removeFile(int index) {
    if (index < 0 || index >= _pendingFiles.length) return;
    setState(() {
      _pendingFiles.removeAt(index);
    });
  }

  String get _recipientHandle {
    final parts = widget.conversation.participantName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '@user';
    if (parts.length == 1) return '@${parts.first}';
    return '@${parts.first}_${parts.last}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DropTarget(
      onDragDone: (detail) {
        _addFiles(detail.files);
        setState(() => _isDragging = false);
      },
      onDragEntered: (detail) {
        setState(() => _isDragging = true);
      },
      onDragExited: (detail) {
        setState(() => _isDragging = false);
      },
      child: Container(
        color: colors.background,
        child: Stack(
          children: [
            Column(
              children: [
                _DmChatHeader(conversation: widget.conversation),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final historyState = ref.watch(chatHistoryProvider(widget.conversation.id));
                      final messages = historyState.messages;

                      return NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (!historyState.isLoading &&
                              historyState.hasMore &&
                              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.8) {
                            ref.read(chatHistoryProvider(widget.conversation.id)).loadMore();
                          }
                          return false;
                        },
                        child: CustomScrollView(
                          reverse: true,
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final msg = messages[index];
                                    return _MessageBubble(message: msg);
                                  },
                                  childCount: messages.length,
                                ),
                              ),
                            ),
                            if (historyState.isLoading)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                              ),
                            if (!historyState.hasMore)
                              SliverToBoxAdapter(
                                child: DmProfileCard(conversation: widget.conversation),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (_pendingFiles.isNotEmpty)
                  _AttachmentPreviewList(
                    files: _pendingFiles,
                    onRemove: _removeFile,
                  ),
                DmMessageComposer(
                  recipientName: _recipientHandle,
                  onSend: (text) {
                    ref.read(chatHistoryProvider(widget.conversation.id)).sendMessage(text, media: List<XFile>.of(_pendingFiles));
                    setState(() {
                      _pendingFiles.clear();
                    });
                  },
                ),
              ],
            ),
            if (_isDragging)
              Positioned.fill(
                child: Container(
                  color: colors.primary.withValues(alpha: 0.2),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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


class _DmChatHeader extends StatelessWidget {
  final DmConversation conversation;

  const _DmChatHeader({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final participantInitial = conversation.participantName.trim().isEmpty
        ? '?'
        : conversation.participantName.trim()[0].toUpperCase();
    
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF6458F5),
            backgroundImage: conversation.participantAvatarUrl != null
                ? NetworkImage(conversation.participantAvatarUrl!)
                : null,
            child: conversation.participantAvatarUrl == null
                ? Text(
                    participantInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            conversation.participantName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BuzzPreparationView(
                  remoteUserName: conversation.participantName,
                  onCancel: () => Navigator.of(context).pop(),
                  onJoin: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => BuzzMeetingView(
                        channelName: conversation.id,
                        token: '',
                        localUid: 0,
                        remoteUserName: conversation.participantName,
                      ),
                    ));
                  },
                ),
              ));
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.phone_outlined, size: 20, color: colors.textHint),
                  const SizedBox(width: 8),
                  Text(
                    'Buzz',
                    style: TextStyle(
                      color: colors.textHint,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isMe = message['userId'] == 'me';
    final content = message['content'] as String? ?? '';
    final createdAt =
        DateTime.tryParse(message['created_at']?.toString() ?? '')?.toLocal() ??
        DateTime.now();

    final timeString = '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF6458F5),
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'User',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF6458F5) : colors.onPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    content,
                    style: TextStyle(
                      color: isMe ? Colors.white : colors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isMe)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      message['status'] == 'sending' ? 'Sending...' : (message['status'] == 'failed' ? 'Failed - Tap to retry' : timeString),
                      style: TextStyle(
                        color: message['status'] == 'failed' ? colors.error : colors.textHint,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentPreviewList extends StatelessWidget {
  final List<XFile> files;
  final Function(int) onRemove;

  const _AttachmentPreviewList({
    required this.files,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: colors.onPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.divider),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.insert_drive_file, color: colors.textHint),
                      const SizedBox(height: 4),
                      Text(
                        file.name,
                        style: TextStyle(color: colors.textPrimary, fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -4,
                right: 4,
                child: InkWell(
                  onTap: () => onRemove(index),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
