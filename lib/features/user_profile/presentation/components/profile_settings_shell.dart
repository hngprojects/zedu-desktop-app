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
    final authState = ref.watch(authNotifierProvider);
    final profileState = ref.watch(userProfileNotifierProvider);
    final userName = authState.user?.fullname.isNotEmpty == true
        ? authState.user!.fullname
        : (profileState.account?.name ?? 'Zedu User');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _ProfileSettingsTopBar(userName: userName),
            Expanded(
              child: Row(
                children: [
                  AppSidebarRail(
                    activeTypeOverride: HomeSidebarType.settings,
                    onTypeSelected: (HomeSidebarType type) {
                      ref.read(homeSidebarProvider.notifier).setType(type);
                      context.go(AppRouter.home);
                    },
                  ),
                  SettingsNavigationSidebar(
                    userName: userName,
                    selectedSection: selectedSection,
                    onSectionSelected: onSectionSelected,
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSettingsTopBar extends StatelessWidget {
  const _ProfileSettingsTopBar({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: context.colors.sidebar,
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
          TopUserMenu(
            userName: userName,
            backgroundColor: context.colors.primary.withValues(alpha: 0.58),
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
                fillColor: context.colors.onPrimary.withValues(alpha: 0.16),
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
