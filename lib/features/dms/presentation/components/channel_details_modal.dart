import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import 'add_channel_members_modal.dart';

class ChannelDetailsModal extends ConsumerStatefulWidget {
  final DmConversation conversation;

  const ChannelDetailsModal({super.key, required this.conversation});

  @override
  ConsumerState<ChannelDetailsModal> createState() =>
      _ChannelDetailsModalState();
}

class _ChannelDetailsModalState extends ConsumerState<ChannelDetailsModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final channelState = ref.watch(channelProvider);
    final channel = channelState.channels.firstWhere(
      (c) => c.id == widget.conversation.channelId,
      orElse: () => Channel(
        id: widget.conversation.channelId,
        name: widget.conversation.displayName.replaceFirst('#', '').trim(),
        description: '',
        organisationId: '',
        ownerId: '',
      ),
    );

    return Dialog(
      backgroundColor: colors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            _buildHeader(channel, colors),
            _buildTabBar(colors, channel.membersCount),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AboutTab(
                    channel: channel,
                    conversation: widget.conversation,
                  ),
                  _PeopleTab(conversation: widget.conversation),
                  const _AgentsTab(),
                  const _FilesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Channel channel, AppPalette colors) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${channel.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colors.borderOutline.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  icon: const Icon(Icons.star_border, size: 18),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colors.borderOutline.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_off_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                  label: const Text(
                    'Mute',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppPalette colors, int memberCount) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.borderOutline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: colors.primary,
        unselectedLabelColor: colors.textPrimary.withValues(alpha: 0.6),
        indicatorColor: colors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: [
          const Tab(text: 'About'),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('People'),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$memberCount',
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Tab(text: 'Agents'),
          const Tab(text: 'Files'),
        ],
      ),
    );
  }
}

class _AboutTab extends ConsumerWidget {
  final Channel channel;
  final DmConversation conversation;

  const _AboutTab({required this.channel, required this.conversation});

  void _showEditDialog(BuildContext context, WidgetRef ref, bool isTopic) {
    final controller = TextEditingController(
      text: isTopic ? channel.topic : channel.description,
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isTopic ? 'Edit Topic' : 'Edit Description',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: context.colors.borderOutline.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Let people know what #${channel.name} is focused on right now (ex. a project milestone).\nTopics are always visible in the header',
                style: TextStyle(
                  fontSize: 11,
                  color: context.colors.textPrimary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      side: BorderSide(
                        color: context.colors.borderOutline.withValues(
                          alpha: 0.2,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: context.colors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (isTopic) {
                        await ref
                            .read(channelProvider.notifier)
                            .updateChannelTopicOrDescription(
                              channelId: channel.id,
                              topic: controller.text,
                            );
                      } else {
                        await ref
                            .read(channelProvider.notifier)
                            .updateChannelTopicOrDescription(
                              channelId: channel.id,
                              description: controller.text,
                            );
                      }
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showArchiveDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Archive this channel?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'When you archive a channel, it\'s archived for everyone. That means...',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '• No one will be able to send messages to the channel',
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Any apps installed in the channel will be disabled',
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• If there are external people in this channel, they will be removed. They\'ll still have access to the chat history.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'You\'ll still be able to find the channel\'s contents via search. And you can always unarchive the channel in the future, if you\'d like.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      side: BorderSide(
                        color: context.colors.borderOutline.withValues(
                          alpha: 0.2,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: context.colors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await ref
                          .read(channelProvider.notifier)
                          .archiveChannel(channel.id, true);
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                        ref
                            .read(activeChatProvider.notifier)
                            .selectChannel('general');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Archive channel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSection(
          context,
          title: 'Topic',
          content: channel.topic?.isNotEmpty == true
              ? channel.topic!
              : 'Add a topic',
          onEdit: () => _showEditDialog(context, ref, true),
        ),
        const Divider(),
        _buildSection(
          context,
          title: 'Description',
          content: channel.description.isNotEmpty
              ? channel.description
              : 'Add a description',
          onEdit: () => _showEditDialog(context, ref, false),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Created by',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${conversation.participants.firstWhere(
                  (p) => p.userId == channel.ownerId,
                  orElse: () => conversation.participants.isNotEmpty ? conversation.participants.first : DmParticipant(userId: '', username: 'Unknown', email: ''),
                ).username} on May 3, 2026',
                style: TextStyle(
                  color: colors.textPrimary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Archive channel for everyone',
            style: TextStyle(color: Colors.red),
          ),
          onTap: () => _showArchiveDialog(context, ref),
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Leave channel',
            style: TextStyle(color: Colors.red),
          ),
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onEdit,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: onEdit,
                child: Text('Edit', style: TextStyle(color: colors.primary)),
              ),
            ],
          ),
          Text(
            content,
            style: TextStyle(color: colors.textPrimary.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _PeopleTab extends ConsumerStatefulWidget {
  final DmConversation conversation;

  const _PeopleTab({required this.conversation});

  @override
  ConsumerState<_PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends ConsumerState<_PeopleTab> {
  String _searchQuery = '';

  void _showUserProfile(DmParticipant participant) {
    final teamMembers = ref.read(userProfileNotifierProvider).teamMembers;
    final found = teamMembers.firstWhere(
      (m) => m.id == participant.userId,
      orElse: () => TeamMember(
        id: participant.userId,
        email: '',
        role: 'Member',
        dateJoined: '',
        status: TeamMemberStatus.active,
        name: participant.username,
        avatarUrl: participant.avatarUrl,
      ),
    );

    Navigator.pop(context); // Close the modal
    ref.read(personalProfilePanelProvider.notifier).state = false;
    ref.read(profileDetailsPanelProvider.notifier).state = found;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final filteredParticipants = widget.conversation.participants.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.username.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Find a user',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: colors.primary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: colors.primary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: colors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.conversation.channelType != 'dm') ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: colors.primary.withValues(alpha: 0.1),
                child: Icon(Icons.person_add_alt_1, color: colors.primary),
              ),
              title: const Text('Add people'),
              onTap: () {
                // Ensure we are working with a channel before allowing adds
                final channelState = ref.read(channelProvider);
                final channel = channelState.channels.firstWhere(
                  (c) => c.id == widget.conversation.channelId,
                  orElse: () => Channel(
                    id: widget.conversation.channelId,
                    name: widget.conversation.displayName
                        .replaceFirst('#', '')
                        .trim(),
                    description: '',
                    organisationId: '',
                    ownerId: '',
                  ),
                );

                showDialog<void>(
                  context: context,
                  builder: (context) => AddChannelMembersModal(
                    channel: channel,
                    conversation: widget.conversation,
                  ),
                );
              },
            ),
          ],
          Expanded(
            child: ListView.builder(
              itemCount: filteredParticipants.length,
              itemBuilder: (context, index) {
                final participant = filteredParticipants[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => _showUserProfile(participant),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundImage: participant.avatarUrl != null
                            ? NetworkImage(participant.avatarUrl!)
                            : null,
                        child: participant.avatarUrl == null
                            ? Text(participant.username[0].toUpperCase())
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.background,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Text(
                        '@${participant.username}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        participant.username,
                        style: TextStyle(
                          color: colors.textPrimary.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
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

class _AgentsTab extends StatelessWidget {
  const _AgentsTab();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Find an agent',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: colors.primary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: colors.primary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: colors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: colors.primary.withValues(alpha: 0.1),
              child: Icon(Icons.smart_toy_outlined, color: colors.primary),
            ),
            title: const Text('Add agents'),
            onTap: () {},
          ),
          Expanded(
            child: Center(
              child: Text(
                'No available agent',
                style: TextStyle(
                  color: colors.textPrimary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilesTab extends StatelessWidget {
  const _FilesTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '🚧 Coming Soon',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'This feature is currently under development.\nPlease check back later!',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
