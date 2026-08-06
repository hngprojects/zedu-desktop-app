import re

with open('lib/features/dms/presentation/components/dm_message_composer.dart', 'r') as f:
    content = f.read()

# Add isMember to DmMessageComposer
content = content.replace(
    'final ValueChanged<String>? onSend;',
    'final ValueChanged<String>? onSend;\n  final bool isMember;'
)
content = content.replace(
    'this.onSend,\n  });',
    'this.onSend,\n    this.isMember = true,\n  });'
)

# Replace the build method of DmMessageComposer to return the non-member banner if not a member
non_member_view = """
    if (!widget.isMember) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        color: colors.primary.withOpacity(0.02),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.recipientName.startsWith('#') ? widget.recipientName : '#${widget.recipientName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'You are not a member of this channel',
              style: TextStyle(color: colors.textPrimary.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Join channel logic
                ref.read(channelProvider.notifier).joinChannel(widget.channelId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.sidebar,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Join channel'),
            ),
          ],
        ),
      );
    }

    final mainColumn = Column("""

content = content.replace('    final mainColumn = Column(', non_member_view)

with open('lib/features/dms/presentation/components/dm_message_composer.dart', 'w') as f:
    f.write(content)

# Now update dm_chat_area.dart
with open('lib/features/dms/presentation/components/dm_chat_area.dart', 'r') as f:
    content2 = f.read()

# Pass isMember to DmMessageComposer
is_member_check = """
                        DmMessageComposer(
                          key: _composerKey,
                          recipientName: _recipientHandle,
                          channelId: widget.conversation.channelId,
                          participants: widget.conversation.participants,
                          isMember: widget.conversation.channelType != 'channel' || ref.watch(channelProvider).channels.any((c) => c.id == widget.conversation.channelId),
                        ),"""

content2 = re.sub(
    r'DmMessageComposer\(\s*key: _composerKey,\s*recipientName: _recipientHandle,\s*channelId: widget.conversation.channelId,\s*participants: widget.conversation.participants,\s*\),',
    is_member_check.strip(),
    content2
)

# There might be another DmMessageComposer instance inside the thread view
is_member_check2 = """
          child: DmMessageComposer(
            key: ValueKey('thread_composer_${_activeThreadId}'),
            recipientName: 'Thread',
            channelId: widget.conversation.channelId,
            participants: widget.conversation.participants,
            isMember: widget.conversation.channelType != 'channel' || ref.watch(channelProvider).channels.any((c) => c.id == widget.conversation.channelId),
          ),"""

content2 = re.sub(
    r'child: DmMessageComposer\(\s*key: ValueKey\(\'thread_composer_\$\{_activeThreadId\}\'\),\s*recipientName: \'Thread\',\s*channelId: widget.conversation.channelId,\s*participants: widget.conversation.participants,\s*\),',
    is_member_check2.strip(),
    content2
)


with open('lib/features/dms/presentation/components/dm_chat_area.dart', 'w') as f:
    f.write(content2)

