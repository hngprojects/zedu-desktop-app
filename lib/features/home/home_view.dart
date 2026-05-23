import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final activeChat = ref.watch(activeChatProvider);
    final userState = ref.watch(userProfileNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    
    String userName = 'Zedu User';
    if (authState.user != null && authState.user!.username.isNotEmpty) {
      userName = authState.user!.username;
    } else if (userState.account?.name != null && userState.account!.name.isNotEmpty) {
      userName = userState.account!.name;
    }
    
    final userInitial = userName.isNotEmpty && userName != 'Zedu User' ? userName[0].toUpperCase() : 'Z';

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          Container(
            height: 50,
            color: colors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Zedu',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poetsen One',
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  offset: const Offset(0, 40),
                  onSelected: (value) async {
                    if (value == 'logout') {
                      await ref.read(authNotifierProvider.notifier).logout();
                      if (context.mounted) {
                        context.go(AppRouter.login);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 20,
                            color: colors.textPrimary,
                          ),
                          const SizedBox(width: 8),
                          const Text('Profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            size: 20,
                            color: colors.error,
                          ),
                          const SizedBox(width: 8),
                          Text('Logout', style: TextStyle(color: colors.error)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.onPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: colors.accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              userInitial,
                              style: TextStyle(
                                color: colors.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          userName,
                          style: TextStyle(
                            color: colors.onPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: colors.onPrimary.withValues(alpha: 0.7),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.onPrimary.withValues(alpha: 0.2),
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
          ),
          Expanded(
            child: Row(
              children: [
                const _SidebarRail(),
                const _MainSidebar(),
                Expanded(
                  child: activeChat.type == ActiveChatType.newGroupChat
                      ? const NewGroupChatView()
                      : activeChat.type == ActiveChatType.channelDirectory
                      ? const ChannelDirectoryView()
                      : const _ChatArea(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarRail extends StatelessWidget {
  const _SidebarRail();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 70,
      decoration: BoxDecoration(
        color: colors.sidebar,
        border: Border(
          right: BorderSide(color: colors.onPrimary.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const _RailNavItem(
            icon: Icons.home_filled,
            label: 'Home',
            isActive: true,
          ),
          const _RailNavItem(icon: Icons.chat_bubble_outline, label: 'DMs'),
          const _RailNavItem(icon: Icons.people_outline, label: 'People'),
          const _RailNavItem(icon: Icons.folder_open_outlined, label: 'Files'),
          const _RailNavItem(icon: Icons.phone_outlined, label: 'Buzz'),
          const Spacer(),
          const _RailBottomIcon(
            icon: Icons.notifications_none_outlined,
            hasNotification: true,
          ),
          const _RailBottomIcon(icon: Icons.settings_outlined),
          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 36,
                    height: 36,
                    color: colors.divider,
                    child: Icon(Icons.person, color: colors.onPrimary),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.sidebar, width: 2),
                    ),
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

class _RailNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _RailNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Icon(icon, color: colors.onPrimary, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: colors.onPrimary,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _RailBottomIcon extends StatelessWidget {
  final IconData icon;
  final bool hasNotification;

  const _RailBottomIcon({required this.icon, this.hasNotification = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        children: [
          Icon(icon, color: colors.onPrimary, size: 24),
          if (hasNotification)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MainSidebar extends ConsumerWidget {
  const _MainSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final groupDms = ref.watch(groupDmProvider);
    final networkStatus = ref.watch(networkStatusProvider);
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final teamMembers = userProfileState.teamMembers;
    final channelState = ref.watch(channelProvider);

    return Container(
      width: 260,
      color: colors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceSwitcherHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Icon(Icons.arrow_drop_down, color: colors.onPrimary, size: 20),
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
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            if (!channelState.channels.any((c) => c.name.toLowerCase() == 'general'))
              const _ChannelItem(label: 'general'),
            ...channelState.channels.take(5).map((channel) {
              return _ChannelItem(label: channel.name);
            }),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () {
                ref.read(activeChatProvider.notifier).selectChannelDirectory();
              },
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
                          color: colors.onPrimary.withValues(alpha: 0.7),
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
          const SizedBox(height: 12),

          // Group DMs Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(Icons.arrow_drop_down, color: colors.onPrimary, size: 20),
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
                IconButton(
                  onPressed: () {
                    ref.read(activeChatProvider.notifier).selectNewGroupChat();
                  },
                  icon: Icon(
                    Icons.add,
                    color: colors.onPrimary.withValues(alpha: 0.8),
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  hoverColor: colors.onPrimary.withValues(alpha: 0.1),
                  splashRadius: 16,
                  tooltip: 'New group DM',
                ),
              ],
            ),
          ),
          if (networkStatus == NetworkStatus.offline)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Connecting...',
                    style: TextStyle(color: colors.error, fontSize: 12),
                  ),
                ],
              ),
            ),
          if (groupDms.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'No group DMs yet',
                style: TextStyle(
                  color: colors.onPrimary.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...groupDms.map((group) => _GroupDmItem(groupDm: group)),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.arrow_right, color: colors.onPrimary, size: 20),
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
          if (teamMembers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'No people yet',
                style: TextStyle(
                  color: colors.onPrimary.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...teamMembers.map((member) => _PersonItem(member: member)),
        ],
      ),
    );
  }
}

class _ChannelItem extends ConsumerWidget {
  final String label;
  const _ChannelItem({required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final activeChat = ref.watch(activeChatProvider);
    final isActive =
        activeChat.type == ActiveChatType.channel && activeChat.id == label;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: InkWell(
        onTap: () {
          ref.read(activeChatProvider.notifier).selectChannel(label);
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? colors.onPrimary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Text(
                '#',
                style: TextStyle(
                  color: colors.onPrimary.withValues(
                    alpha: isActive ? 0.9 : 0.54,
                  ),
                  fontSize: 18,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.onPrimary.withValues(
                      alpha: isActive ? 1.0 : 0.8,
                    ),
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupDmItem extends ConsumerWidget {
  final GroupDM groupDm;
  const _GroupDmItem({required this.groupDm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final activeChat = ref.watch(activeChatProvider);
    final isActive =
        activeChat.type == ActiveChatType.groupDm &&
        activeChat.id == groupDm.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: InkWell(
        onTap: () {
          ref.read(activeChatProvider.notifier).selectGroupDm(groupDm.id);
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? colors.onPrimary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(
                Icons.people_alt_outlined,
                color: colors.onPrimary.withValues(alpha: isActive ? 0.9 : 0.6),
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  groupDm.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onPrimary.withValues(
                      alpha: isActive ? 1.0 : 0.8,
                    ),
                    fontSize: 14,
                    fontWeight: isActive || groupDm.unreadCount > 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (groupDm.unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${groupDm.unreadCount}',
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
        ),
      ),
    );
  }
}

class _PersonItem extends ConsumerWidget {
  final TeamMember member;
  const _PersonItem({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final activeChat = ref.watch(activeChatProvider);
    final isActive =
        activeChat.type == ActiveChatType.directMessage &&
        activeChat.id == member.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: InkWell(
        onTap: () {
          ref.read(activeChatProvider.notifier).selectDirectMessage(member.id);
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? colors.onPrimary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: colors.onPrimary.withValues(
                      alpha: isActive ? 0.9 : 0.6,
                    ),
                    size: 16,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: member.status == TeamMemberStatus.active
                            ? colors.success
                            : colors.textHint,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.sidebar, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  member.name ?? member.email.split('@').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onPrimary.withValues(
                      alpha: isActive ? 1.0 : 0.8,
                    ),
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddChannelButton extends StatelessWidget {
  const _AddChannelButton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (context) => const CreateChannelModal(),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    );
  }
}

enum RightPanelType { none, thread, search, groupDetails }

class _ChatArea extends ConsumerStatefulWidget {
  const _ChatArea();

  @override
  ConsumerState<_ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends ConsumerState<_ChatArea> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  RightPanelType _rightPanel = RightPanelType.none;
  String? _activeThreadMessage;
  String? _activeThreadAuthor;
  final Map<String, List<String>> _channelMessages = {'general': []};

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(ActiveChatState activeChat, String text) {
    if (activeChat.type == ActiveChatType.groupDm) {
      if (activeChat.id != null) {
        ref.read(groupDmProvider.notifier).sendMessage(activeChat.id!, text);
      }
    } else if (activeChat.type == ActiveChatType.channel) {
      final channelId = activeChat.id ?? 'general';
      setState(() {
        _channelMessages.putIfAbsent(channelId, () => []).add(text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeChat = ref.watch(activeChatProvider);
    final networkStatus = ref.watch(networkStatusProvider);
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildChatHeader(context, activeChat),
              if (networkStatus == NetworkStatus.offline)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  color: colors.error.withValues(alpha: 0.1),
                  alignment: Alignment.center,
                  child: Text(
                    'You are offline. Showing cached messages.',
                    style: TextStyle(
                      color: colors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Expanded(child: _buildChatBody(context, activeChat)),
              MessageComposer(
                activeChat: activeChat,
                onSend: (text) => _sendMessage(activeChat, text),
              ),
            ],
          ),
        ),
        if (_rightPanel == RightPanelType.search)
          SearchPanel(
            onClose: () => setState(() => _rightPanel = RightPanelType.none),
          )
        else if (_rightPanel == RightPanelType.thread &&
            _activeThreadMessage != null)
          ThreadPanel(
            parentMessage: _activeThreadMessage!,
            parentAuthor: _activeThreadAuthor ?? 'You',
            onClose: () => setState(() => _rightPanel = RightPanelType.none),
          )
        else if (_rightPanel == RightPanelType.groupDetails &&
            activeChat.type == ActiveChatType.groupDm)
          GroupDetailsPanel(
            group: ref
                .watch(groupDmProvider)
                .firstWhere(
                  (g) => g.id == activeChat.id,
                  orElse: () =>
                      const GroupDM(id: '', name: 'Group DM', members: []),
                ),
            onClose: () => setState(() => _rightPanel = RightPanelType.none),
            onRename: (newName) {
              // Mock rename
              ref
                  .read(groupDmProvider.notifier)
                  .renameGroupDm(activeChat.id!, newName);
            },
            onLeave: () {
              // Mock leave
              setState(() => _rightPanel = RightPanelType.none);
              ref.read(activeChatProvider.notifier).selectChannel('general');
            },
          ),
      ],
    );
  }

  Widget _buildChatHeader(BuildContext context, ActiveChatState activeChat) {
    final colors = context.colors;
    String title = '';
    bool isGroup = false;

    Channel? currentChannel;
    if (activeChat.type == ActiveChatType.groupDm) {
      isGroup = true;
      final group = ref
          .watch(groupDmProvider)
          .firstWhere(
            (g) => g.id == activeChat.id,
            orElse: () => const GroupDM(id: '', name: 'Group DM', members: []),
          );
      title = group.name;
    } else if (activeChat.type == ActiveChatType.channel) {
      final channels = ref.watch(channelProvider).channels;
      currentChannel = channels
          .where((c) => c.name == activeChat.id || c.id == activeChat.id)
          .firstOrNull;
      title = '# ${currentChannel?.name ?? activeChat.id ?? "general"}';
    } else {
      title = '# ${activeChat.id ?? "general"}';
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          if (isGroup) ...[
            Icon(
              Icons.people_alt_outlined,
              color: colors.textPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          _HeaderAction(icon: Icons.headphones_outlined, label: 'Start Buzz'),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              setState(() => _rightPanel = RightPanelType.search);
            },
            icon: Icon(Icons.search, color: colors.textHint),
            splashRadius: 20,
            tooltip: 'Search',
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 14,
            backgroundColor: colors.accent,
            child: Icon(Icons.person, size: 18, color: colors.onPrimary),
          ),
          IconButton(
            onPressed: () {
              if (isGroup) {
                setState(() => _rightPanel = RightPanelType.groupDetails);
              } else if (currentChannel != null) {
                showDialog<void>(
                  context: context,
                  builder: (context) =>
                      EditChannelModal(channel: currentChannel!),
                );
              }
            },
            icon: Icon(Icons.more_vert, color: colors.textHint),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildChatBody(BuildContext context, ActiveChatState activeChat) {
    if (activeChat.type == ActiveChatType.groupDm) {
      final group = ref
          .watch(groupDmProvider)
          .firstWhere(
            (g) => g.id == activeChat.id,
            orElse: () => const GroupDM(id: '', name: 'Group DM', members: []),
          );
      return _buildGroupDmBody(context, group);
    } else {
      final channelId = activeChat.id ?? 'general';
      final messages = _channelMessages[channelId] ?? [];
      return _buildChannelBody(context, channelId, messages);
    }
  }

  Widget _buildGroupDmBody(BuildContext context, GroupDM group) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      itemCount: group.messages.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildGroupDmWelcome(context, group);
        }
        final message = group.messages[index - 1];
        final isSystem = message.startsWith('Group DM created');
        final author = isSystem ? 'System' : 'You';

        return GestureDetector(
          onSecondaryTap: () {
            setState(() {
              _rightPanel = RightPanelType.thread;
              _activeThreadMessage = message;
              _activeThreadAuthor = author;
            });
          },
          child: MessageBubble(
            author: author,
            text: message,
            timestamp: '3:15 PM',
            isSystem: isSystem,
          ),
        );
      },
    );
  }

  Widget _buildGroupDmWelcome(BuildContext context, GroupDM group) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.group_outlined, size: 60, color: colors.primary),
        const SizedBox(height: 24),
        Text(
          'This is the start of your Group DM',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Members: ${group.name}',
          style: TextStyle(fontSize: 15, color: colors.textHint),
        ),
        const SizedBox(height: 24),
        Divider(color: colors.divider),
      ],
    );
  }

  Widget _buildChannelBody(
    BuildContext context,
    String channelId,
    List<String> messages,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildChannelWelcome(context, channelId);
        }
        final message = messages[index - 1];

        return GestureDetector(
          onSecondaryTap: () {
            setState(() {
              _rightPanel = RightPanelType.thread;
              _activeThreadMessage = message;
              _activeThreadAuthor = 'You';
            });
          },
          child: MessageBubble(
            author: 'You',
            text: message,
            timestamp: '3:15 PM',
          ),
        );
      },
    );
  }

  Widget _buildChannelWelcome(BuildContext context, String channelId) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.celebration, size: 60, color: colors.primary),
        const SizedBox(height: 24),
        Text(
          'Welcome to #$channelId',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Share all information relating to $channelId here. All team members await you! 😉',
          style: TextStyle(fontSize: 16, color: colors.textPrimary),
        ),
        const SizedBox(height: 32),
        const _InviteCard(),
        const SizedBox(height: 24),
        Divider(color: colors.divider),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: colors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textPrimary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (context) => InviteTeammatesModal(),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: colors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primaryBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_add_alt, color: colors.primary),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite teammates',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  'Add your entire team in seconds',
                  style: TextStyle(color: colors.textHint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
