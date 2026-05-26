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
                        Expanded(
                          child: TextField(
                            onChanged: (val) {
                              ref.read(dmSearchQueryProvider.notifier).state = val;
                            },
                            style: TextStyle(
                              color: colors.onPrimary.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Find a Conversation',
                              hintStyle: TextStyle(
                                color: colors.onPrimary.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.only(bottom: 12),
                            ),
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
            child: Consumer(
              builder: (context, ref, child) {
                final query = ref.watch(dmSearchQueryProvider);
                if (query.isNotEmpty) {
                  return ref.watch(dmSearchResultsProvider).when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (err, stack) => Center(
                      child: Text(
                        'Failed to search',
                        style: TextStyle(color: colors.error),
                      ),
                    ),
                    data: (members) {
                      if (members.isEmpty) {
                        return Center(
                          child: Text(
                            'No members found',
                            style: TextStyle(
                              color: colors.onPrimary.withValues(alpha: 0.5),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundImage: member.avatarUrl != null
                                  ? NetworkImage(member.avatarUrl!)
                                  : null,
                              child: member.avatarUrl == null
                                  ? const Icon(Icons.person, size: 16)
                                  : null,
                            ),
                            title: Text(
                              member.name ?? 'Unknown',
                              style: TextStyle(
                                color: colors.onPrimary.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              member.email,
                              style: TextStyle(
                                color: colors.onPrimary.withValues(alpha: 0.6),
                                fontSize: 11,
                              ),
                            ),
                            onTap: () {
                              final currentUser = ref.read(authNotifierProvider).user;
                              final isSelf = currentUser?.id == member.id;
                              
                              final nameStr = member.name ?? 'Unknown';
                              final conversation = DmConversation(
                                channelId: isSelf ? 'dm_${member.id}_${member.id}' : 'dm_temp_${member.id}',
                                username: isSelf ? '$nameStr (You)' : nameStr,
                                participantId: member.id,
                                previewMessage: 'Start a new conversation',
                                unreadCount: 0,
                                avatarUrl: member.avatarUrl,
                              );
                              ref.read(selectedDmProvider.notifier).select(conversation);
                              ref.read(dmSearchQueryProvider.notifier).state = '';
                            },
                          );
                        },
                      );
                    },
                  );
                }

                return ref.watch(dmListProvider).when(
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
                    if (conversations.isEmpty) {
                      return Center(
                        child: Text(
                          'No recent chats',
                          style: TextStyle(
                            color: colors.onPrimary.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }
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
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          return DmListTile(conversation: conversations[index]);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
