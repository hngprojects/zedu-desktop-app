import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class UserMenuDialog extends ConsumerWidget {
  const UserMenuDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final menuState = ref.watch(userMenuStateProvider);
    final menuNotifier = ref.read(userMenuStateProvider.notifier);

    return Dialog(
      insetPadding: const EdgeInsets.only(bottom: 24, left: 74),
      alignment: Alignment.bottomLeft,
      backgroundColor: colors.background,
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User Profile Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.colors.sidebar,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AnonymousUser',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            menuState.isAway ? 'Away' : 'Active',
                            style: TextStyle(
                              color: menuState.isAway
                                  ? colors.textHint
                                  : colors.success,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 0, color: colors.divider),
              const SizedBox(height: 8),

              // Update Your Status
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog<void>(
                      context: context,
                      builder: (context) => const UpdateStatusDialog(),
                    );
                  },
                  icon: Icon(
                    Icons.sentiment_satisfied_alt,
                    size: 20,
                    color: colors.textPrimary,
                  ),
                  label: Text(
                    'Update your status',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    alignment: Alignment.centerLeft,
                    side: BorderSide(color: colors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Set Yourself as Away
              _MenuItemButton(
                icon: Icons.access_time,
                label: 'Set yourself as away',
                trailing: Icon(
                  menuState.isAway ? Icons.check : Icons.close,
                  size: 18,
                  color: menuState.isAway ? colors.success : colors.textHint,
                ),
                onTap: menuNotifier.toggleAwayStatus,
              ),
              const SizedBox(height: 12),

              // Pause Notifications
              _MenuItemButton(
                icon: Icons.notifications_off_outlined,
                label: 'Pause notifications',
                trailing: Icon(
                  menuState.notificationsPaused ? Icons.check : Icons.close,
                  size: 18,
                  color: menuState.notificationsPaused
                      ? colors.success
                      : colors.textHint,
                ),
                onTap: menuNotifier.toggleNotifications,
              ),
              const SizedBox(height: 12),
              Divider(height: 0, color: colors.divider),
              const SizedBox(height: 8),

              // Profile
              _MenuItemButton(
                icon: Icons.person_outline,
                label: 'Profile...',
                onTap: () => _openSettings(context, ref),
              ),
              const SizedBox(height: 12),

              _MenuItemButton(
                icon: Icons.settings_outlined,
                label: 'Preferences...',
                onTap: () => _openSettings(context, ref),
              ),
              const SizedBox(height: 12),

              // Buy AI Credit
              _MenuItemButton(
                icon: Icons.shopping_cart_outlined,
                label: 'Buy AI credits',
                isHighlight: true,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              Divider(height: 0, color: colors.divider),
              const SizedBox(height: 8),

              // Logout
              _MenuItemButton(
                icon: Icons.logout_rounded,
                label: 'Sign out of Zedu users',
                isError: true,
                onTap: () async {
                  Navigator.pop(context);
                  // Access ref through context to avoid closure issues
                  final authRef = ref.read(authNotifierProvider.notifier);
                  await authRef.logout();
                  if (context.mounted) {
                    context.go(AppRouter.login);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItemButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isHighlight;
  final bool isError;

  const _MenuItemButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.isHighlight = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final itemColor = isError
        ? colors.error
        : (isHighlight ? colors.accent : colors.textPrimary);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: itemColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: itemColor,
                  fontSize: 13,
                  fontWeight: isHighlight || isError
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

void _openSettings(BuildContext context, WidgetRef ref) {
  Navigator.pop(context);
  if (context.mounted) {
    openWorkspaceSettings(ref, context: context);
  }
}
