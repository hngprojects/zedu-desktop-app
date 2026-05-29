import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orgId = ref.read(authNotifierProvider).user?.currentOrg;
      if (orgId != null && orgId.isNotEmpty) {
        ref.read(creditsNotifierProvider.notifier).load(orgId: orgId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final showProfile = ref.watch(personalProfilePanelProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const _HomeAppBar(),
          Expanded(
            child: Row(
              children: [
                AppSidebarRail(activeType: ref.watch(homeSidebarProvider)),
                const _MainSidebarSwitcher(),
                Expanded(
                  child: Stack(
                    children: [
                      const Positioned.fill(child: _ChatAreaSwitcher()),
                      if (showProfile)
                        const Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: PersonalProfilePanel(),
                        ),
                    ],
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

class _HomeAppBar extends ConsumerWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final userName =
        ref.watch(authNotifierProvider).user?.fullname ?? 'Zedu User';

    return Container(
      height: 44,
      color: colors.sidebar,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            'Zedu',
            style: TextStyle(
              color: colors.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poetsen One',
            ),
          ),
          const SizedBox(width: 12),
          TopUserMenu(userName: userName),
          const Spacer(),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              height: 28,
              decoration: BoxDecoration(
                color: colors.onPrimary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(
                    Icons.search,
                    color: colors.onPrimary.withValues(alpha: 0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Search messages...',
                    style: TextStyle(
                      color: colors.onPrimary.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _MainSidebarSwitcher extends ConsumerWidget {
  const _MainSidebarSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeSidebarProvider);
    if (state == HomeSidebarType.dms) {
      return const DmSidebarList();
    }
    return const _MainSidebar();
  }
}

void _showCreateChannelDialog(BuildContext context, WidgetRef ref) {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  bool isPrivate = false;

  showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create a Channel'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Channel Name',
                    hintText: 'e.g. team-marketing',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'What is this channel about?',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Make Private'),
                    Switch(
                      value: isPrivate,
                      onChanged: (val) {
                        setState(() => isPrivate = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    AppToastService.show(
                      context,
                      type: AppToastType.error,
                      message: 'Channel name cannot be empty',
                    );
                    return;
                  }

                  final channelState = ref.read(channelProvider);
                  final isDuplicate = channelState.channels.any(
                    (c) => c.name.toLowerCase() == name.toLowerCase(),
                  );

                  if (isDuplicate) {
                    AppToastService.show(
                      context,
                      type: AppToastType.error,
                      message: 'A channel with this name already exists',
                    );
                    return;
                  }

                  final success = await ref
                      .read(channelProvider.notifier)
                      .createChannel(
                        name: name,
                        description: descController.text.trim(),
                        isPrivate: isPrivate,
                      );

                  if (success && context.mounted) {
                    Navigator.of(context).pop();
                    AppToastService.show(
                      context,
                      type: AppToastType.success,
                      message: 'Channel #$name created successfully!',
                    );
                  } else if (context.mounted) {
                    AppToastService.show(
                      context,
                      type: AppToastType.error,
                      message: 'Failed to create channel.',
                    );
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _ChatAreaSwitcher extends ConsumerWidget {
  const _ChatAreaSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeChat = ref.watch(activeChatProvider);

    switch (activeChat.type) {
      case ActiveChatType.directMessage:
        final selectedDm = ref.watch(selectedDmProvider);
        if (selectedDm != null && selectedDm.channelId == activeChat.id) {
          return DmChatArea(
            key: ValueKey('dm_${selectedDm.channelId}'),
            conversation: selectedDm,
          );
        }
        final conversations = ref.watch(dmListProvider).value ?? [];
        final conv = conversations.firstWhere(
          (c) => c.channelId == activeChat.id,
          orElse: () => DmConversation(
            channelId: activeChat.id ?? '',
            username: 'Direct Message',
            participantId: activeChat.id ?? '',
            previewMessage: '',
            unreadCount: 0,
          ),
        );
        return DmChatArea(
          key: ValueKey('dm_${conv.channelId}'),
          conversation: conv,
        );

      case ActiveChatType.channel:
        final channelState = ref.watch(channelProvider);
        final channelId = activeChat.id;
        final channel = channelState.channels.firstWhere(
          (c) => c.id == channelId || (channelId != null && c.name.toLowerCase() == channelId.toLowerCase()),
          orElse: () => Channel(
            id: channelId ?? '',
            name: channelId ?? 'general',
            description: '',
            organisationId: '',
            ownerId: '',
          ),
        );
        final teamMembers = ref.watch(userProfileNotifierProvider).teamMembers;
        final participants = teamMembers.map((m) => DmParticipant(
          userId: m.id,
          username: m.name ?? m.email.split('@').first,
          email: m.email,
          avatarUrl: m.avatarUrl,
        )).toList();

        final conversation = DmConversation(
          channelId: channel.id,
          username: '#${channel.name}',
          participantId: channel.ownerId,
          previewMessage: channel.description,
          unreadCount: channel.unreadCount,
          channelType: 'channel',
          participants: participants,
        );
        return DmChatArea(
          key: ValueKey('channel_${conversation.channelId}'),
          conversation: conversation,
        );

      case ActiveChatType.groupDm:
        final groups = ref.watch(groupDmProvider);
        final group = groups.firstWhere(
          (g) => g.id == activeChat.id,
          orElse: () =>
              GroupDM(id: activeChat.id ?? '', name: 'Group DM', members: []),
        );
        final conversation = DmConversation(
          channelId: group.id,
          username: group.name,
          participantId: 'group-dm',
          previewMessage: group.messages.isEmpty ? '' : group.messages.last,
          unreadCount: group.unreadCount,
          channelType: 'group_dm',
          participants: group.members.map((m) => DmParticipant(
            userId: m.id,
            username: m.name ?? m.email.split('@').first,
            email: m.email,
            avatarUrl: m.avatarUrl,
          )).toList(),
        );
        return DmChatArea(
          key: ValueKey('group_${conversation.channelId}'),
          conversation: conversation,
        );

      case ActiveChatType.channelDirectory:
        return const ChannelDirectoryView();

      case ActiveChatType.newGroupChat:
        return const NewGroupChatView();
    }
  }
}

class _MainSidebar extends ConsumerWidget {
  const _MainSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final channelState = ref.watch(channelProvider);
    final channels = channelState.channels;
    final activeChat = ref.watch(activeChatProvider);
    final notificationSettings = ref.watch(notificationSettingsProvider);
    final activeChannels = channels.where((c) => !c.archived).toList();

    return Container(
      width: 320,
      color: colors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceSwitcherHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_drop_down,
                          color: colors.onPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Channels',
                          style: TextStyle(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (channelState.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  else if (activeChannels.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text(
                        'No active channels',
                        style: TextStyle(
                          color: colors.onPrimary.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeChannels.length,
                      itemBuilder: (context, index) {
                        final channel = activeChannels[index];
                        final isSelected =
                            activeChat.type == ActiveChatType.channel &&
                            (activeChat.id == channel.id ||
                                (activeChat.id != null && activeChat.id!.toLowerCase() == channel.name.toLowerCase()));
                        final isMuted = notificationSettings.isChannelMuted(channel.id);
                        return _ChannelItem(
                          key: ValueKey(channel.id),
                          label: channel.name,
                          isPrivate: channel.isPrivate,
                          isSelected: isSelected,
                          isMuted: isMuted,
                          onTap: () {
                            ref
                                .read(activeChatProvider.notifier)
                                .selectChannel(channel.id);
                          },
                        );
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: InkWell(
                      onTap: () {
                        ref
                            .read(activeChatProvider.notifier)
                            .selectChannelDirectory();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colors.onPrimary.withValues(alpha: 0.24),
                          ),
                          borderRadius: BorderRadius.circular(6),
                          color: colors.onPrimary.withValues(alpha: 0.05),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'View all channels',
                                style: TextStyle(
                                  color: colors.onPrimary.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: colors.onPrimary.withValues(alpha: 0.7),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const _AddChannelButton(),
                  const SizedBox(height: 10),
                  const _GroupDmsSection(),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_drop_down,
                          color: colors.onPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'People',
                          style: TextStyle(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, child) {
                      final teamMembers = ref.watch(userProfileNotifierProvider).teamMembers;
                      if (teamMembers.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Text(
                            'No members found',
                            style: TextStyle(
                              color: colors.onPrimary.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: teamMembers.length,
                        itemBuilder: (context, index) {
                          final member = teamMembers[index];
                          final name = member.name ?? member.email.split('@').first;
                          
                          // Find DM conversation for this member if exists
                          final conversations = ref.watch(dmListProvider).value ?? [];
                          final existing = conversations.firstWhere(
                            (c) => c.participantId == member.id,
                            orElse: () => DmConversation(
                              channelId: member.id,
                              username: name,
                              participantId: member.id,
                              previewMessage: '',
                              unreadCount: 0,
                            ),
                          );

                          final isSelected = activeChat.type == ActiveChatType.directMessage &&
                              (activeChat.id == existing.channelId || activeChat.id == member.id);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  ref.read(selectedDmProvider.notifier).select(existing);
                                  ref.read(activeChatProvider.notifier).selectDirectMessage(existing.channelId);
                                },
                                borderRadius: BorderRadius.circular(6),
                                hoverColor: colors.onPrimary.withValues(alpha: 0.08),
                                splashColor: colors.onPrimary.withValues(alpha: 0.12),
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
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundColor: colors.primary,
                                        backgroundImage: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                                            ? NetworkImage(member.avatarUrl!)
                                            : null,
                                        child: member.avatarUrl == null || member.avatarUrl!.isEmpty
                                            ? Text(
                                                name.substring(0, 1).toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          name,
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
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelItem extends StatelessWidget {
  final String label;
  final bool isPrivate;
  final bool isSelected;
  final bool isMuted;
  final VoidCallback onTap;

  const _ChannelItem({
    super.key,
    required this.label,
    this.isPrivate = false,
    this.isSelected = false,
    this.isMuted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textOpacity = isMuted ? 0.4 : (isSelected ? 0.95 : 0.8);
    final iconOpacity = isMuted ? 0.4 : (isSelected ? 0.95 : 0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          hoverColor: colors.onPrimary.withValues(alpha: 0.08),
          splashColor: colors.onPrimary.withValues(alpha: 0.12),
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
                  isPrivate ? Icons.lock_outline : Icons.tag,
                  color: colors.onPrimary.withValues(
                    alpha: iconOpacity,
                  ),
                  size: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: colors.onPrimary.withValues(
                        alpha: textOpacity,
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
                if (isMuted) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.volume_off_rounded,
                    color: colors.onPrimary.withValues(alpha: 0.4),
                    size: 14,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddChannelButton extends ConsumerWidget {
  const _AddChannelButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: () => _showCreateChannelDialog(context, ref),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colors.onPrimary.withValues(alpha: 0.38),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.add, color: colors.onPrimary, size: 14),
              ),
              const SizedBox(width: 12),
              Text(
                'Add channel',
                style: TextStyle(color: colors.onPrimary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ref.read(activeChatProvider.notifier).selectGroupDm(group.id);
                    },
                    borderRadius: BorderRadius.circular(6),
                    hoverColor: colors.onPrimary.withValues(alpha: 0.08),
                    splashColor: colors.onPrimary.withValues(alpha: 0.12),
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
                ),
              );
            },
          ),
      ],
    );
  }
}
