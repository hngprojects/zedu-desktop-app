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
                              ref.read(dmSearchQueryProvider.notifier).state =
                                  val;
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
                  return ref
                      .watch(dmSearchResultsProvider)
                      .when(
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
                                  color: colors.onPrimary.withValues(
                                    alpha: 0.5,
                                  ),
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
                                leading: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: member.avatarUrl != null
                                      ? Image.network(
                                          member.avatarUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Center(
                                                    child: Icon(
                                                      Icons.person,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.person,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                                title: Text(
                                  member.name ?? 'Unknown',
                                  style: TextStyle(
                                    color: colors.onPrimary.withValues(
                                      alpha: 0.9,
                                    ),
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  member.email,
                                  style: TextStyle(
                                    color: colors.onPrimary.withValues(
                                      alpha: 0.6,
                                    ),
                                    fontSize: 11,
                                  ),
                                ),
                                onTap: () => openOrCreateDm(
                                  context: context,
                                  ref: ref,
                                  memberId: member.id,
                                  memberName: member.name ?? 'Unknown',
                                  memberEmail: member.email,
                                  memberAvatarUrl: member.avatarUrl,
                                  isSelf:
                                      ref.read(authNotifierProvider).user?.id ==
                                      member.id,
                                ),
                              );
                            },
                          );
                        },
                      );
                }

                return ref
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
                        return Column(
                          children: [
                            const _GroupDmsSection(),
                            Expanded(
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (scrollInfo) {
                                  if (scrollInfo is ScrollEndNotification &&
                                      scrollInfo.metrics.pixels >=
                                          scrollInfo.metrics.maxScrollExtent * 0.85) {
                                    final notifier = ref.read(
                                      dmListProvider.notifier,
                                    );
                                    if (notifier.hasMore) notifier.loadMore();
                                  }
                                  return false;
                                },
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: conversations.length,
                                  itemBuilder: (context, index) {
                                    return DmListTile(
                                      conversation: conversations[index],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
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

  /// Shared logic: look up an existing conversation by [memberId], create a
  /// DM channel on the backend if needed, then navigate to the chat.
  /// Called both from the search results list and from [DmListTile].
  static Future<void> openOrCreateDm({
    required BuildContext context,
    required WidgetRef ref,
    required String memberId,
    required String memberName,
    required String memberEmail,
    String? memberAvatarUrl,
    bool isSelf = false,
  }) async {
    // 1. Look for an existing conversation with a VALID channel ID first.
    final existingList = ref.read(dmListProvider).value ?? [];
    DmConversation? existingConvo;
    try {
      existingConvo = existingList.firstWhere(
        (c) =>
            c.participantId == memberId &&
            DmRepository.isValidChannelId(c.channelId),
      );
    } catch (_) {
      existingConvo = null;
    }

    // 2. If no valid conversation found, create one on the backend.
    if (existingConvo == null) {
      try {
        final orgId = ref.read(currentOrgIdProvider);
        final repo = ref.read(dmRepositoryProvider);
        existingConvo = await repo.createDmChannel(
          orgId: orgId,
          userId: memberId,
        );
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to create conversation. '
                'Please check your connection and try again.',
              ),
            ),
          );
        }
        return;
      }
    }

    // 3. Safety guard — if the backend still returned an invalid ID, abort.
    if (!DmRepository.isValidChannelId(existingConvo.channelId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not establish a conversation channel. '
              'Please try again.',
            ),
          ),
        );
      }
      return;
    }

    // 4. Navigate.
    ref.read(dmListProvider.notifier).addConversation(existingConvo);
    ref.read(selectedDmProvider.notifier).select(existingConvo);
    ref.read(activeChatProvider.notifier).selectDirectMessage(existingConvo.channelId);
    ref.read(dmSearchQueryProvider.notifier).state = '';

    // 5. Clear unread badge.
    ref.read(dmListProvider.notifier).markConversationRead(
      existingConvo.channelId,
    );
  }
}

class _GroupDmsSection extends ConsumerWidget {
  const _GroupDmsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final groupDms = ref.watch(groupDmProvider);
    final activeChat = ref.watch(activeChatProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  ref.read(activeChatProvider.notifier).selectNewGroupChat();
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colors.onPrimary.withValues(alpha: 0.38),
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
        if (groupDms.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'No group DMs',
              style: TextStyle(
                color: colors.onPrimary.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          )
        else
          ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: groupDms.length,
            itemBuilder: (context, index) {
              final group = groupDms[index];
              final isSelected = activeChat.type == ActiveChatType.groupDm &&
                  activeChat.id == group.id;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ref.read(activeChatProvider.notifier).selectGroupDm(group.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.onPrimary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: colors.onPrimary.withValues(
                            alpha: isSelected ? 0.95 : 0.6,
                          ),
                          size: 16,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            group.name,
                            style: TextStyle(
                              color: colors.onPrimary.withValues(
                                alpha: isSelected ? 0.95 : 0.8,
                              ),
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
