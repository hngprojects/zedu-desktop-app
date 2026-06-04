import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class DmListTile extends ConsumerWidget {
  final DmConversation conversation;

  const DmListTile({super.key, required this.conversation});

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(dt.year, dt.month, dt.day);

    if (messageDay == today) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (messageDay == yesterday) return 'Yesterday';

    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final selected = ref.watch(selectedDmProvider);
    final isSelected = selected?.channelId == conversation.channelId;
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: () => DmSidebarList.openOrCreateDm(
        context: context,
        ref: ref,
        memberId: conversation.participantId,
        memberName: conversation.displayName,
        memberEmail: '',
        memberAvatarUrl: conversation.effectiveAvatarUrl,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.onPrimary.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border(
            top: BorderSide(color: colors.onPrimary.withValues(alpha: 0.18)),
            bottom: BorderSide(color: colors.onPrimary.withValues(alpha: 0.18)),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 36,
              height: 36,
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
                          conversation.displayName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        conversation.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            // Name + preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.displayName,
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    parseHtmlToMarkdown(conversation.previewMessage),
                    style: TextStyle(
                      color: colors.onPrimary.withValues(alpha: 0.86),
                      fontSize: 11,
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
                  _formatTime(conversation.lastActivityAt),
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.92),
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
                      color: colors.primary,
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
