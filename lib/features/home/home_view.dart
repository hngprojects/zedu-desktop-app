import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryColor = Color(0xFF303073);
    const topBarColor = Color(0xFF7141F8);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Top Bar
          Container(
            height: 50,
            color: topBarColor,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Zedu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poetsen One',
                  ),
                ),
                const SizedBox(width: 12),
                // Zedu User Dropdown
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
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 20,
                            color: Colors.black87,
                          ),
                          SizedBox(width: 8),
                          Text('Profile'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            size: 20,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: TextStyle(color: Colors.redAccent),
                          ),
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
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5CCBBA),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              'ZU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Zedu User',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Search Bar
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 8),
                        Icon(Icons.search, color: Colors.white70, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Search messages...',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
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
                // 2. Sidebar Rail
                const _SidebarRail(backgroundColor: primaryColor),

                // 3. Main Sidebar
                const _MainSidebar(backgroundColor: primaryColor),

                // 4. Chat Area
                const Expanded(child: _ChatArea()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarRail extends StatelessWidget {
  final Color backgroundColor;
  const _SidebarRail({required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
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
          // Bottom Section
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
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: backgroundColor, width: 2),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          if (hasNotification)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MainSidebar extends StatelessWidget {
  final Color backgroundColor;
  const _MainSidebar({required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceSwitcherHeader(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Channels',
                  style: TextStyle(
                    color: Colors.white,
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
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(6),
                color: Colors.white.withValues(alpha: 0.05),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'View all channels',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),
          const _AddChannelButton(),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.arrow_right, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'People',
                  style: TextStyle(
                    color: Colors.white,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Text(
            '#',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _AddChannelButton extends StatelessWidget {
  const _AddChannelButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white38,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 12),
          const Text(
            'Add channel',
            style: TextStyle(color: Colors.white, fontSize: 14),
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
        _buildChatHeader(),
        Expanded(child: _buildWelcomeScreen()),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildChatHeader() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          const Text(
            '# general',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          _HeaderAction(icon: Icons.headphones_outlined, label: 'Start Buzz'),
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 14,
            backgroundColor: Colors.tealAccent,
            child: Icon(Icons.person, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.more_vert, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.celebration, size: 60, color: Colors.amber),
          const SizedBox(height: 24),
          const Text(
            'Welcome to #general',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share all information relating to general here. All team members await you! 😉',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 32),
          _InviteCard(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.format_bold, size: 20, color: Colors.black54),
                SizedBox(width: 16),
                Icon(Icons.format_italic, size: 20, color: Colors.black54),
                SizedBox(width: 16),
                Icon(Icons.link, size: 20, color: Colors.black54),
                SizedBox(width: 16),
                Icon(Icons.list, size: 20, color: Colors.black54),
                SizedBox(width: 16),
                Icon(Icons.code, size: 20, color: Colors.black54),
              ],
            ),
            const Divider(height: 24),
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
                const Icon(Icons.add, color: Colors.black38),
                const SizedBox(width: 12),
                const Icon(
                  Icons.emoji_emotions_outlined,
                  color: Colors.black38,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.alternate_email, color: Colors.black38),
                const SizedBox(width: 12),
                const Icon(Icons.videocam_outlined, color: Colors.black38),
                const SizedBox(width: 12),
                const Icon(Icons.mic_none_outlined, color: Colors.black38),
                const Spacer(),
                const Icon(Icons.send_rounded, color: Colors.black26),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_alt, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invite teammates',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'Add your entire team in seconds',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
