import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ProfileSettingsShell extends ConsumerWidget {
  const ProfileSettingsShell({
    super.key,
    required this.selectedSection,
    required this.onSectionSelected,
    required this.child,
  });

  static const _brand = Color(0xFF303073);
  static const _rail = Color(0xFF39368A);
  static const _active = Color(0xFF6458F5);

  final UserProfileSection selectedSection;
  final ValueChanged<UserProfileSection> onSectionSelected;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userProfileNotifierProvider);
    final userName = state.account?.name ?? 'Zedu User';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _ProfileTopBar(userName: userName),
            Expanded(
              child: Row(
                children: [
                  const _PrimaryRail(),
                  _SettingsNavigation(
                    userName: userName,
                    selectedSection: selectedSection,
                    onSectionSelected: onSectionSelected,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Expanded(child: child)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({required this.userName});
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: ProfileSettingsShell._brand,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Image.asset(
            'assets/pngs/zedu_logo.png',
            width: 82,
            height: 31,
            color: Colors.white,
            colorBlendMode: BlendMode.srcIn,
          ),
          const SizedBox(width: 24),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF4D49AC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF13C9BD),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'zu',
                    style: TextStyle(color: Colors.white, fontSize: 8),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  userName,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search messages...',
                hintStyle: context.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 18,
                ),
                filled: true,
                fillColor: const Color(0xFF5751BC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: context.textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _PrimaryRail extends StatelessWidget {
  const _PrimaryRail();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, 'Home'),
      (Icons.chat_bubble_outline, 'DMs'),
      (Icons.person_outline, 'People'),
      (Icons.insert_drive_file_outlined, 'Files'),
      (Icons.call_outlined, 'Buzz'),
    ];

    return Container(
      width: 64,
      color: ProfileSettingsShell._rail,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          for (final item in items)
            _RailItem(
              icon: item.$1,
              label: item.$2,
              selected: item.$2 == 'DMs',
            ),
          const Spacer(),
          const _RailIcon(icon: Icons.notifications_none, badge: true),
          const SizedBox(height: 12),
          const _RailIcon(icon: Icons.settings_outlined, selected: true),
          const SizedBox(height: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.person, color: Color(0xFF303073)),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: ProfileSettingsShell._rail),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          _RailIcon(icon: icon, selected: selected),
          const SizedBox(height: 3),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _RailIcon extends StatelessWidget {
  const _RailIcon({
    required this.icon,
    this.selected = false,
    this.badge = false,
  });

  final IconData icon;
  final bool selected;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: selected ? ProfileSettingsShell._active : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        if (badge)
          Positioned(
            right: 5,
            top: 5,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _SettingsNavigation extends StatelessWidget {
  const _SettingsNavigation({
    required this.userName,
    required this.selectedSection,
    required this.onSectionSelected,
  });

  final String userName;
  final UserProfileSection selectedSection;
  final ValueChanged<UserProfileSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: ProfileSettingsShell._rail,
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: context.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  userName,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white70,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 30),
          const _NavigationGroupLabel(label: 'Personal'),
          _NavigationTile(
            icon: Icons.person_outline,
            label: 'Account',
            selected: selectedSection == UserProfileSection.account,
            onTap: () => onSectionSelected(UserProfileSection.account),
          ),
          _NavigationTile(
            icon: Icons.notifications_none,
            label: 'Notifications',
            selected: selectedSection == UserProfileSection.notifications,
            onTap: () => onSectionSelected(UserProfileSection.notifications),
          ),
          _NavigationTile(
            icon: Icons.lock_outline,
            label: 'Security',
            selected: selectedSection == UserProfileSection.security,
            onTap: () => onSectionSelected(UserProfileSection.security),
          ),
          const SizedBox(height: 18),
          const _NavigationGroupLabel(label: 'Organization'),
          _NavigationTile(
            icon: Icons.settings_outlined,
            label: 'General',
            selected: selectedSection == UserProfileSection.organization,
            onTap: () => onSectionSelected(UserProfileSection.organization),
          ),
          _NavigationTile(
            icon: Icons.groups_outlined,
            label: 'User management',
            selected: selectedSection == UserProfileSection.userManagement,
            onTap: () => onSectionSelected(UserProfileSection.userManagement),
          ),
          _NavigationTile(
            icon: Icons.person_outline,
            label: 'Roles & permissions',
            selected: selectedSection == UserProfileSection.rolesAndPermissions,
            onTap: () =>
                onSectionSelected(UserProfileSection.rolesAndPermissions),
          ),
          _NavigationTile(
            icon: Icons.credit_card_outlined,
            label: 'Billing',
            selected: selectedSection == UserProfileSection.billing,
            onTap: () => onSectionSelected(UserProfileSection.billing),
          ),
        ],
      ),
    );
  }
}

class _NavigationGroupLabel extends StatelessWidget {
  const _NavigationGroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? ProfileSettingsShell._active : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
