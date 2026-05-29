import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class DmSidebarList extends ConsumerWidget {
  const DmSidebarList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Container(
      width: 320,
      color: colors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceSwitcherHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: colors.onPrimary.withValues(alpha: 0.68),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Icon(
                          Icons.search,
                          color: colors.onPrimary.withValues(alpha: 0.9),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Find a Conversation',
                          style: TextStyle(
                            color: colors.onPrimary.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ref
                .watch(dmListProvider)
                .when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'Failed to load DMs',
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                  data: (conversations) {
                    final groupDms = ref.watch(groupDmProvider);
                    final groupConversations = groupDms.map((g) {
                      return DmConversation(
                        channelId: g.id,
                        username: g.name,
                        participantId: 'group-dm',
                        previewMessage: g.messages.isEmpty
                            ? ''
                            : g.messages.last,
                        unreadCount: g.unreadCount,
                        channelType: 'group_dm',
                        participants: g.members.map((m) => DmParticipant(
                          userId: m.id,
                          username: m.name ?? m.email.split('@').first,
                          email: m.email,
                          avatarUrl: m.avatarUrl,
                        )).toList(),
                      );
                    }).toList();

                    return NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo is ScrollEndNotification &&
                            scrollInfo.metrics.pixels >=
                                scrollInfo.metrics.maxScrollExtent * 0.85) {
                          final notifier = ref.read(dmListProvider.notifier);
                          if (notifier.hasMore) {
                            notifier.loadMore();
                          }
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // DIRECT MESSAGES SECTION
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: colors.onPrimary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Direct Messages',
                                    style: TextStyle(
                                      color: colors.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (conversations.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'No recent direct messages',
                                  style: TextStyle(
                                    color: colors.onPrimary.withValues(
                                      alpha: 0.5,
                                    ),
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: conversations.length,
                                itemBuilder: (context, index) {
                                  return DmListTile(
                                    conversation: conversations[index],
                                  );
                                },
                              ),

                            const SizedBox(height: 20),

                            // GROUP DMs SECTION
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: colors.onPrimary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Group DMs',
                                      style: TextStyle(
                                        color: colors.onPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      ref
                                          .read(activeChatProvider.notifier)
                                          .selectNewGroupChat();
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: colors.onPrimary.withValues(
                                            alpha: 0.38,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        color: colors.onPrimary,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (groupConversations.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'No recent group DMs',
                                  style: TextStyle(
                                    color: colors.onPrimary.withValues(
                                      alpha: 0.5,
                                    ),
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: groupConversations.length,
                                itemBuilder: (context, index) {
                                  return DmListTile(
                                    conversation: groupConversations[index],
                                  );
                                },
                              ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
