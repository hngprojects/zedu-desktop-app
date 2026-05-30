import re

with open('lib/features/dms/presentation/components/dm_chat_area.dart', 'r') as f:
    content = f.read()

new_header = """class _DmChatHeader extends StatelessWidget {
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
    final isChannel = conversation.channelType == 'channel' || conversation.channelType == 'group_dm';
    
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
            isChannel ? conversation.displayName.replaceFirst('#', '').trim() : conversation.displayName,
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
                    ref.read(activeCallProvider.notifier).initiateCall(
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
                showDialog(
                  context: context,
                  builder: (_) => ChannelDetailsModal(conversation: conversation),
                );
              },
            ),
            Consumer(
              builder: (context, ref, child) {
                return PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colors.textHint),
                  onSelected: (value) async {
                    if (value == 'details') {
                      showDialog(
                        context: context,
                        builder: (_) => ChannelDetailsModal(conversation: conversation),
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
                      child: Text('Open channel details', style: TextStyle(fontSize: 13)),
                    ),
                    const PopupMenuItem(
                      value: 'notifications',
                      child: Text('Notification Settings', style: TextStyle(fontSize: 13)),
                    ),
                    const PopupMenuItem(
                      value: 'search',
                      child: Text('Search in channel', style: TextStyle(fontSize: 13)),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'leave',
                      child: Text('Leave channel', style: TextStyle(fontSize: 13, color: Colors.red)),
                    ),
                  ],
                );
              },
            ),
          ] else ...[
            // DM logic remains same
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
                      ref.read(notificationServiceProvider).handleIncomingMessage(
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
                    ref.read(activeCallProvider.notifier).initiateCall(
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
}"""

pattern = re.compile(r'class _DmChatHeader extends StatelessWidget \{.*?^\}\n*class _MessageBubble', re.MULTILINE | re.DOTALL)
new_content = pattern.sub(new_header + '\n\nclass _MessageBubble', content)

with open('lib/features/dms/presentation/components/dm_chat_area.dart', 'w') as f:
    f.write(new_content)
