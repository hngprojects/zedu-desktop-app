import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key, this.initialChannelId});

  final String? initialChannelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

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
                              'ZU',
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
                          'Zedu User',
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
                  child: ChannelsView(initialChannelId: initialChannelId),
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
          const _ChannelItem(
            label: 'general',
            channelId: ChannelsDevDefaults.mockChannelId,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        ],
      ),
    );
  }
}

class _ChannelItem extends ConsumerWidget {
  const _ChannelItem({required this.label, required this.channelId});

  final String label;
  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return InkWell(
      onTap: () {
        ref.read(channelsNotifierProvider.notifier).openChannel(channelId);
        context.go('/home/channels/$channelId');
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
            Text(label, style: TextStyle(color: colors.onPrimary, fontSize: 15)),
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
            style: TextStyle(color: colors.onPrimary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
