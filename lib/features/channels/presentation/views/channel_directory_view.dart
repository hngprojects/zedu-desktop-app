import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ChannelDirectoryView extends ConsumerStatefulWidget {
  const ChannelDirectoryView({super.key});

  @override
  ConsumerState<ChannelDirectoryView> createState() =>
      _ChannelDirectoryViewState();
}

class _ChannelDirectoryViewState extends ConsumerState<ChannelDirectoryView>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateChannelModal() {
    showDialog<void>(
      context: context,
      builder: (context) => const CreateChannelModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channelState = ref.watch(channelProvider);
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final colors = context.colors;
    final textTheme = context.textTheme;

    final filteredChannels = channelState.channels.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredPeople = userProfileState.teamMembers.where((m) {
      if (_searchQuery.isEmpty) return true;
      return (m.name?.toLowerCase() ?? '').contains(
            _searchQuery.toLowerCase(),
          ) ||
          m.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Directories',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Browse all the people and channels in your workspace.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TabBar(
          controller: _tabController,
          indicatorColor: colors.primary,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          tabs: const [
            Tab(text: 'People'),
            Tab(text: 'Channels'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPeopleTab(filteredPeople, colors, textTheme),

              _buildChannelsTab(
                filteredChannels,
                channelState,
                colors,
                textTheme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeopleTab(
    List<TeamMember> people,
    AppPalette colors,
    TextTheme textTheme,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search people',
              prefixIcon: Icon(Icons.search, color: colors.textHint),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.divider),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
          ),
        ),
        Expanded(
          child: people.isEmpty
              ? Center(
                  child: Text(
                    'No people found.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: people.length,
                  itemBuilder: (context, index) {
                    final person = people[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 8.0,
                      ),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: colors.primary.withValues(alpha: 0.1),
                        backgroundImage: person.avatarUrl != null
                            ? NetworkImage(person.avatarUrl!)
                            : null,
                        child: person.avatarUrl == null
                            ? Text(
                                (person.name ?? person.email)
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: TextStyle(color: colors.primary),
                              )
                            : null,
                      ),
                      title: Text(
                        person.name ?? person.email,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        person.role,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      onTap: () {},
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChannelsTab(
    List<Channel> channels,
    ChannelState state,
    AppPalette colors,
    TextTheme textTheme,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.primary.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Organize your team\'s conversations',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Channels are where your team communicates. They’re best when organized around a topic — #marketing, for example.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                ElevatedButton(
                  onPressed: _showCreateChannelModal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.sidebar,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Create channel'),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search channels',
                    prefixIcon: Icon(Icons.search, color: colors.textHint),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colors.divider),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.divider),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      'All channels',
                      style: TextStyle(color: colors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.keyboard_arrow_down, color: colors.textHint),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : channels.isEmpty
              ? Center(
                  child: Text(
                    'No channels found.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: channels.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: colors.divider),
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    final activeChannels = ref.read(channelProvider).channels;
                    final isMember = activeChannels.any(
                      (c) => c.id == channel.id,
                    );

                    return InkWell(
                      onTap: () async {
                        if (!isMember) {
                          await ref
                              .read(channelProvider.notifier)
                              .joinChannel(channel.id);
                        }
                        ref
                            .read(activeChatProvider.notifier)
                            .selectChannel(channel.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: channel.isPrivate
                                    ? Icon(
                                        Icons.lock,
                                        size: 20,
                                        color: colors.textSecondary,
                                      )
                                    : Text(
                                        '#',
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    channel.name,
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  if (channel.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      channel.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 14,
                                        color: colors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${channel.membersCount} members',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        isMember ? 'Joined' : 'Leave',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: isMember
                                              ? colors.success
                                              : colors.textSecondary,
                                          fontWeight: isMember
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
