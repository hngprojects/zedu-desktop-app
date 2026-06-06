import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
// import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
// import 'package:window_manager/window_manager.dart';
// import '../providers/org_people_provider.dart';
import '../widgets/people_sidebar_list.dart';
import '../../../dms/presentation/components/global_call_overlay.dart';

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
        // ref.read(creditsNotifierProvider.notifier).load(orgId: orgId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final showPersonalProfile = ref.watch(personalProfilePanelProvider);
    final otherProfile = ref.watch(profileDetailsPanelProvider);
    final showOtherProfile = otherProfile != null;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Column(
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
                          if (showPersonalProfile)
                            const Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: PersonalProfilePanel(),
                            )
                          else if (showOtherProfile)
                            const Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: ProfileDetailsPanel(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const GlobalCallOverlay(),
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

    return DragToMoveArea(
      child: Container(
        height: 44,
        color: colors.sidebar,
        padding: const EdgeInsets.only(left: 24, right: 10),
        child: Row(
          children: [
            Image.asset(
              'assets/pngs/zedu_logo.png',
              width: 82,
              height: 31,
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
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
            if (!kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.windows ||
                    defaultTargetPlatform == TargetPlatform.macOS ||
                    defaultTargetPlatform == TargetPlatform.linux))
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  WindowCaptionButton.minimize(
                    brightness: Brightness.dark,
                    onPressed: () async => await windowManager.minimize(),
                  ),
                  WindowCaptionButton.maximize(
                    brightness: Brightness.dark,
                    onPressed: () async {
                      if (await windowManager.isMaximized()) {
                        await windowManager.unmaximize();
                      } else {
                        await windowManager.maximize();
                      }
                    },
                  ),
                  WindowCaptionButton.close(
                    brightness: Brightness.dark,
                    onPressed: () async => await windowManager.close(),
                  ),
                ],
              ),
          ],
        ),
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
    if (state == HomeSidebarType.people) {
      return const PeopleSidebarList();
    }
    if (state == HomeSidebarType.buzz) {
      return const SizedBox.shrink(); // Buzz is full-width; no secondary sidebar
    }
    if (state == HomeSidebarType.files) {
      // FilesView provides its own internal left panel
      return const SizedBox.shrink();
    }
    return const _MainSidebar();
  }
}

class _ChatAreaSwitcher extends ConsumerWidget {
  const _ChatAreaSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeChat = ref.watch(activeChatProvider);
    final sidebar = ref.watch(homeSidebarProvider);

    // ── Files tab: always show the Files UI ───────────────────────────────
    if (sidebar == HomeSidebarType.files) {
      return const _FilesView();
    }

    // ── Buzz tab: full-width meeting hub ───────────────────────────────────
    if (sidebar == HomeSidebarType.buzz) {
      final callStatus = ref.watch(activeCallProvider).state.status;
      final buzzStatus = ref.watch(orgBuzzProvider).status;

      if (callStatus == CallStatus.active) {
        // "Get a link" flow: user is in the meeting AND the ready card should
        // be shown as a centred overlay on top of the live meeting room.
        if (buzzStatus == OrgBuzzStatus.readyForLater) {
          final buzz = ref.watch(orgBuzzProvider);
          return Stack(
            children: [
              const BuzzMeetingView(),
              Positioned.fill(
                child: Material(
                  color: Colors.black.withValues(alpha: 0.40),
                  child: Center(
                    child: BuzzReadyCard(
                      meetingLink: buzz.meetingLink ?? '',
                      buzzId: buzz.buzzId ?? '',
                      onJoin: () =>
                          ref.read(orgBuzzProvider.notifier).dismissReadyCard(),
                      onDismiss: () =>
                          ref.read(orgBuzzProvider.notifier).dismissReadyCard(),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return const BuzzMeetingView();
      }
      if (callStatus == CallStatus.calling) {
        final callState = ref.watch(activeCallProvider).state;
        return BuzzPreparationView(
          remoteUserName: callState.remoteUserName ?? 'Unknown',
          onCancel: () => ref.read(activeCallProvider.notifier).cancelCall(),
          onJoin: () {},
        );
      }
      return const GeneralBuzzView();
    }

    // ── DMs / People: if no DM or Group chat is active, show empty state ──
    if (sidebar == HomeSidebarType.dms || sidebar == HomeSidebarType.people) {
      if (activeChat.type != ActiveChatType.directMessage &&
          activeChat.type != ActiveChatType.groupDm) {
        return const _EmptyChatArea();
      }
    }

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
          (c) => c.id == channelId || c.name == channelId,
          orElse: () => Channel(
            id: channelId ?? '',
            name: channelId ?? 'general',
            description: '',
            organisationId: '',
            ownerId: '',
          ),
        );
        final conversation = DmConversation(
          channelId: channel.id,
          username: '#${channel.name}',
          participantId: channel.ownerId,
          previewMessage: channel.description,
          unreadCount: channel.unreadCount,
          channelType: 'channel',
        );

        if (channel.name == 'general') {
          return const _WelcomeChatArea();
        }

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
        final groupConv = DmConversation(
          channelId: group.id,
          username: group.name,
          participantId: 'group-dm',
          previewMessage: group.messages.isEmpty ? '' : group.messages.last,
          unreadCount: group.unreadCount,
          channelType: 'group_dm',
        );
        return DmChatArea(
          key: ValueKey('group_${groupConv.channelId}'),
          conversation: groupConv,
        );

      case ActiveChatType.channelDirectory:
        return const ChannelDirectoryView();

      case ActiveChatType.newGroupChat:
        return const NewGroupChatView();

      default:
        return const _EmptyChatArea();
    }
  }
}

class _MainSidebar extends ConsumerStatefulWidget {
  const _MainSidebar();

  @override
  ConsumerState<_MainSidebar> createState() => _MainSidebarState();
}

class _MainSidebarState extends ConsumerState<_MainSidebar> {
  bool _channelsExpanded = true;
  bool _peopleExpanded = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 320,
      color: colors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceSwitcherHeader(),

          // Channels
          InkWell(
            onTap: () {
              setState(() {
                _channelsExpanded = !_channelsExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Icon(
                    _channelsExpanded
                        ? Icons.arrow_drop_down
                        : Icons.arrow_right,
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
          ),

          if (_channelsExpanded) ...[
            const _ChannelItem(label: 'general'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            const _AddChannelButton(),
          ],

          const SizedBox(height: 20),

          // People
          InkWell(
            onTap: () {
              setState(() {
                _peopleExpanded = !_peopleExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    _peopleExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
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
          ),

          if (_peopleExpanded) ...[
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final peopleState = ref.watch(userProfileNotifierProvider);
                if (peopleState.isLoading && peopleState.teamMembers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  );
                }
                final people = peopleState.teamMembers;
                if (people.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Text(
                      'No team members yet.',
                      style: TextStyle(
                        color: colors.onPrimary.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  );
                }
                return Column(
                  children: people.map((person) {
                    final name = person.name ?? person.email.split('@').first;
                    final List<Color> avatarColors = [
                      Colors.purple,
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.red,
                      Colors.teal,
                    ];
                    final colorIndex = person.id.hashCode % avatarColors.length;
                    final avatarColor = avatarColors[colorIndex];

                    return InkWell(
                      onTap: () async {
                        final orgId = ref.read(currentOrgIdProvider);

                        final dmRepo = ref.read(dmRepositoryProvider);
                        final conv = await dmRepo.createDmChannel(
                          orgId: orgId,
                          userId: person.id,
                        );

                        ref
                            .read(homeSidebarProvider.notifier)
                            .setType(HomeSidebarType.dms);
                        ref.read(selectedDmProvider.notifier).select(conv);
                        ref
                            .read(activeChatProvider.notifier)
                            .selectDirectMessage(conv.channelId);
                        // Bring the conversation to the top of the DM list
                        ref
                            .read(dmListProvider.notifier)
                            .bringToTop(conv.channelId);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: avatarColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  color: colors.onPrimary,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
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

    return InkWell(
      onTap: () {
        ref.read(activeChatProvider.notifier).selectChannel(label);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Text(
              '#',
              style: TextStyle(
                color: colors.onPrimary.withValues(alpha: 0.54),
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: colors.onPrimary, fontSize: 15),
            ),
          ],
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

    return Padding(
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
            style: TextStyle(
              color: colors.onPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeChatArea extends StatelessWidget {
  const _WelcomeChatArea();

  @override
  Widget build(BuildContext context) {
    return const _ChatArea();
  }
}

class _EmptyChatArea extends StatelessWidget {
  const _EmptyChatArea();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.onPrimary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/pngs/recent_message.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              'Recent Messages',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatArea extends StatelessWidget {
  const _ChatArea();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildChatHeader(context),
        Expanded(child: _buildWelcomeScreen(context)),
        _buildMessageInput(context),
      ],
    );
  }

  Widget _buildChatHeader(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          Text(
            '# general',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          const _HeaderAction(
            icon: Icons.headphones_outlined,
            label: 'Start Buzz',
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 14,
            backgroundColor: colors.accent,
            child: Icon(Icons.person, size: 18, color: colors.onPrimary),
          ),
          const SizedBox(width: 8),
          Icon(Icons.more_vert, color: colors.textHint),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.celebration, size: 60, color: colors.primary),
          const SizedBox(height: 24),
          Text(
            'Welcome to #general',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share all information relating to general here. All team members await you! 😉',
            style: TextStyle(fontSize: 16, color: colors.textPrimary),
          ),
          const SizedBox(height: 32),
          const _InviteCard(),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: colors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.format_bold, size: 20, color: colors.textHint),
                const SizedBox(width: 16),
                Icon(Icons.format_italic, size: 20, color: colors.textHint),
                const SizedBox(width: 16),
                Icon(Icons.link, size: 20, color: colors.textHint),
                const SizedBox(width: 16),
                Icon(Icons.list, size: 20, color: colors.textHint),
                const SizedBox(width: 16),
                Icon(Icons.code, size: 20, color: colors.textHint),
              ],
            ),
            Divider(height: 24, color: colors.divider),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Message #general',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.add, color: colors.textHint.withValues(alpha: 0.75)),
                const SizedBox(width: 12),
                Icon(
                  Icons.emoji_emotions_outlined,
                  color: colors.textHint.withValues(alpha: 0.75),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.alternate_email,
                  color: colors.textHint.withValues(alpha: 0.75),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.videocam_outlined,
                  color: colors.textHint.withValues(alpha: 0.75),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.mic_none_outlined,
                  color: colors.textHint.withValues(alpha: 0.75),
                ),
                const Spacer(),
                Icon(
                  Icons.send_rounded,
                  color: colors.textHint.withValues(alpha: 0.5),
                ),
              ],
            ),
          ],
        ),
      ),
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
            style: TextStyle(color: colors.textPrimary, fontSize: 13),
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
          barrierColor: Colors.black.withValues(alpha: 0.3),
          builder: (context) => const InviteTeammatesModal(),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: colors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.primaryBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.person_add_outlined, color: colors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite teammates',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add more team members to collaborate',
                    style: TextStyle(color: colors.textHint, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textHint),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Files View
// ─────────────────────────────────────────────────────────────────────────────

enum _FilesNav { allFiles, myFiles, sharedWithMe, deleted }

class _FilesView extends StatefulWidget {
  const _FilesView();

  @override
  State<_FilesView> createState() => _FilesViewState();
}

class _FilesViewState extends State<_FilesView> {
  _FilesNav _selected = _FilesNav.allFiles;
  int _selectedTab = 0; // 0 = Folders, 1 = Files

  String get _title {
    switch (_selected) {
      case _FilesNav.allFiles:
        return 'All files';
      case _FilesNav.myFiles:
        return 'My files';
      case _FilesNav.sharedWithMe:
        return 'Shared with me';
      case _FilesNav.deleted:
        return 'Deleted files';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        // ── Left sidebar ──────────────────────────────────────────────────
        Container(
          width: 220,
          decoration: BoxDecoration(
            color: colors.sidebar,
            border: Border(
              right: BorderSide(color: colors.onPrimary.withValues(alpha: 0.1)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Files',
                        style: TextStyle(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.edit_outlined,
                      color: colors.onPrimary.withValues(alpha: 0.7),
                      size: 18,
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.onPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      Icon(
                        Icons.search,
                        color: colors.onPrimary.withValues(alpha: 0.5),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Find a file',
                        style: TextStyle(
                          color: colors.onPrimary.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Nav items
              _FilesNavItem(
                icon: Icons.folder_outlined,
                label: 'All files',
                isSelected: _selected == _FilesNav.allFiles,
                onTap: () => setState(() => _selected = _FilesNav.allFiles),
                colors: colors,
              ),
              _FilesNavItem(
                icon: Icons.person_outline,
                label: 'My files',
                isSelected: _selected == _FilesNav.myFiles,
                onTap: () => setState(() => _selected = _FilesNav.myFiles),
                colors: colors,
              ),
              _FilesNavItem(
                icon: Icons.group_outlined,
                label: 'Shared with me',
                isSelected: _selected == _FilesNav.sharedWithMe,
                onTap: () => setState(() => _selected = _FilesNav.sharedWithMe),
                colors: colors,
              ),
              _FilesNavItem(
                icon: Icons.delete_outline,
                label: 'Deleted files',
                isSelected: _selected == _FilesNav.deleted,
                onTap: () => setState(() => _selected = _FilesNav.deleted),
                colors: colors,
              ),
            ],
          ),
        ),

        // ── Main content ──────────────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: colors.onPrimary,
                  border: Border(
                    bottom: BorderSide(
                      color: colors.onPrimary == Colors.white
                          ? const Color(0xFFE5E7EB)
                          : colors.onPrimary.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    // Upload file button
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.upload_outlined, size: 16),
                      label: const Text('Upload file'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // New folder button
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.create_new_folder_outlined,
                        size: 16,
                      ),
                      label: const Text('New folder'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs: Folders | Files
              Container(
                color: colors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _FilesTab(
                      label: 'Folders',
                      isSelected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                      colors: colors,
                    ),
                    _FilesTab(
                      label: 'Files',
                      isSelected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                      colors: colors,
                    ),
                  ],
                ),
              ),

              // Divider
              Container(height: 1, color: const Color(0xFFE5E7EB)),

              // Empty state (shared by all nav items)
              Expanded(
                child: Container(
                  color: colors.onPrimary,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.folder_open_outlined,
                            size: 40,
                            color: colors.textHint,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No files yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload or drag & drop to get started',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilesNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppPalette colors;

  const _FilesNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.onPrimary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? colors.onPrimary
                  : colors.onPrimary.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected
                    ? colors.onPrimary
                    : colors.onPrimary.withValues(alpha: 0.6),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilesTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppPalette colors;

  const _FilesTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        margin: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? colors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? colors.primary : colors.textHint,
          ),
        ),
      ),
    );
  }
}
