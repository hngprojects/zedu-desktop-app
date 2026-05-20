import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class DmListTile extends ConsumerWidget {
  final DmConversation conversation;

  const DmListTile({super.key, required this.conversation});

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final selected = ref.watch(selectedDmProvider);
    final isSelected = selected?.id == conversation.id;
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: () {
        ref.read(selectedDmProvider.notifier).state = conversation;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.onPrimary.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
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
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            // Name + message preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.participantName,
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontSize: 14,
                      fontWeight:
                          hasUnread ? FontWeight.bold : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.lastMessage,
                    style: TextStyle(
                      color: colors.onPrimary.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Timestamp + unread badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(conversation.lastMessageAt),
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6458F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
