import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ProfileSettingsShell extends ConsumerWidget {
  const ProfileSettingsShell({
    super.key,
    required this.selectedSection,
    required this.onSectionSelected,
    required this.child,
  });

  final UserProfileSection selectedSection;
  final ValueChanged<UserProfileSection> onSectionSelected;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userProfileNotifierProvider);
    final userName = state.account?.name ?? 'Zedu User';

    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _SettingsNavigation(
            userName: userName,
            selectedSection: selectedSection,
            onSectionSelected: onSectionSelected,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ),
                Divider(height: 1, color: context.colors.divider),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
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
      color: context.colors.sidebar,
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
            color: selected ? context.colors.primary : Colors.transparent,
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
