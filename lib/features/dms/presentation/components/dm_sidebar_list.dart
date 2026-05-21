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
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.onPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Icon(
                          Icons.search,
                          color: colors.onPrimary.withValues(alpha: 0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Find a Conversation',
                          style: TextStyle(
                            color: colors.onPrimary.withValues(alpha: 0.7),
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
                ),
          ),
        ],
      ),
    );
  }
}
