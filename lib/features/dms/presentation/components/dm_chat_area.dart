import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class DmChatArea extends ConsumerWidget {
  final DmConversation conversation;

  const DmChatArea({super.key, required this.conversation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Container(
      color: colors.background,
      child: Column(
        children: [
          _DmChatHeader(conversation: conversation),
          Expanded(
            child: CustomScrollView(
              reverse: true, // Messages build bottom-up
              slivers: [
                // Paginating message list would go here.
                // Currently just the profile card at the top.
                SliverToBoxAdapter(
                  child: DmProfileCard(conversation: conversation),
                ),
              ],
            ),
          ),
          DmMessageComposer(
            recipientName: '@${conversation.participantName.split(' ').first}_${conversation.participantName.split(' ').last}',
            onSend: (text) {
              // TODO: Wire to repository sendMessage
            },
          ),
        ],
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
                    conversation.participantName[0].toUpperCase(),
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
          // Buzz Start Call Button (Phase 6 placeholder)
          InkWell(
            onTap: () {
              // TODO: Integrate Buzz/Agora
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
