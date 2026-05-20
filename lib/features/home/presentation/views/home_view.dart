import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          _HomeAppBar(ref: ref),
          Expanded(
            child: Row(
              children: [
                const _SidebarRail(),
                const _MainSidebarSwitcher(),
                const Expanded(child: _ChatAreaSwitcher()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget {
  final WidgetRef ref;

  const _HomeAppBar({required this.ref});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
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
          const TopUserMenu(userName: 'Zedu User'),
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
    );
  }
}

class _SidebarRail extends ConsumerWidget {
  const _SidebarRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          _RailNavItem(
            icon: Icons.home_filled,
            label: 'Home',
            isActive: ref.watch(homeSidebarProvider) == HomeSidebarType.home,
            onTap: () => ref.read(homeSidebarProvider.notifier).state = HomeSidebarType.home,
          ),
          _RailNavItem(
            icon: Icons.chat_bubble_outline, 
            label: 'DMs',
            isActive: ref.watch(homeSidebarProvider) == HomeSidebarType.dms,
            onTap: () => ref.read(homeSidebarProvider.notifier).state = HomeSidebarType.dms,
          ),
          _RailNavItem(
            icon: Icons.people_outline, 
            label: 'People',
            isActive: ref.watch(homeSidebarProvider) == HomeSidebarType.people,
            onTap: () => ref.read(homeSidebarProvider.notifier).state = HomeSidebarType.people,
          ),
          _RailNavItem(
            icon: Icons.folder_open_outlined, 
            label: 'Files',
            isActive: ref.watch(homeSidebarProvider) == HomeSidebarType.files,
            onTap: () => ref.read(homeSidebarProvider.notifier).state = HomeSidebarType.files,
          ),
          _RailNavItem(
            icon: Icons.phone_outlined, 
            label: 'Buzz',
            isActive: ref.watch(homeSidebarProvider) == HomeSidebarType.buzz,
            onTap: () => ref.read(homeSidebarProvider.notifier).state = HomeSidebarType.buzz,
          ),
          const Spacer(),
          const _RailBottomIcon(
            icon: Icons.notifications_none_outlined,
            hasNotification: true,
          ),
          const _RailBottomIcon(icon: Icons.settings_outlined),
          const Padding(
            padding: EdgeInsets.only(bottom: 16, top: 8),
            child: UserMenuButton(),
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
  final VoidCallback? onTap;

  const _RailNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
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

class _ChatAreaSwitcher extends ConsumerWidget {
  const _ChatAreaSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeSidebarProvider);
    final selectedDm = ref.watch(selectedDmProvider);
    
    if (state == HomeSidebarType.dms && selectedDm != null) {
      return DmChatArea(conversation: selectedDm);
    }
    return const _ChatArea();
  }
}

class _MainSidebar extends StatelessWidget {
  const _MainSidebar();

  @override
  Widget build(BuildContext context) {
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
          const _ChannelItem(label: 'general'),
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

class _ChannelItem extends StatelessWidget {
  final String label;

  const _ChannelItem({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
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
          _HeaderAction(icon: Icons.headphones_outlined, label: 'Start Buzz'),
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
                hintText: 'Message Ruby - Social Media Handler',
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

    return Container(
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
    );
  }
}
