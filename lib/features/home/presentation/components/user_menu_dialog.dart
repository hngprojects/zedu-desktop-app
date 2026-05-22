import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class UserMenuDialog extends ConsumerStatefulWidget {
  const UserMenuDialog({super.key});

  @override
  ConsumerState<UserMenuDialog> createState() => _UserMenuDialogState();
}

class _UserMenuDialogState extends ConsumerState<UserMenuDialog> {
  bool _isEmojiPickerOpen = false;
  String? _selectedEmoji;

  final List<String> _emojis = const [
    '😀', '😅', '😊', '😍', '😎', '🤔',
    '😴', '🥳', '😭', '😡', '👍', '🙏',
    '🔥', '✨', '🎉', '🚀', '👀', '💯',
    '❤️', '🙌', '👏', '🤝', '💼', '💻',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final menuState = ref.watch(userMenuStateProvider);
    final menuNotifier = ref.read(userMenuStateProvider.notifier);
    final authUser = ref.watch(authNotifierProvider).user;
    final balance = ref.watch(orgCreditBalanceProvider);
    final displayName = authUser?.fullname ?? 'AnonymousUser';

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
                            displayName,
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
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$balance AI credits',
                                style: TextStyle(
                                  color: colors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
              const SizedBox(height: 12),
              Divider(height: 0, color: colors.divider),
              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isEmojiPickerOpen = !_isEmojiPickerOpen;
                        });
                      },
                      icon: _selectedEmoji != null
                          ? Text(_selectedEmoji!, style: const TextStyle(fontSize: 18))
                          : Icon(
                              Icons.sentiment_satisfied_alt,
                              size: 20,
                              color: colors.textPrimary,
                            ),
                      label: Text(
                        _selectedEmoji != null ? 'Status updated' : 'Update your status',
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
                    if (_isEmojiPickerOpen) ...[
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _emojis.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedEmoji = _emojis[index];
                                _isEmojiPickerOpen = false;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Center(
                              child: Text(
                                _emojis[index],
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

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

              _MenuItemButton(
                icon: Icons.person_outline,
                label: 'Profile...',
                onTap: () {
                  Navigator.pop(context);
                  ref.read(personalProfilePanelProvider.notifier).state = true;
                },
              ),
              const SizedBox(height: 12),

              _MenuItemButton(
                icon: Icons.settings_outlined,
                label: 'Preferences...',
                onTap: () {
                  Navigator.pop(context);
                  if (context.mounted) {
                    context.go(AppRouter.profile);
                  }
                },
              ),
              const SizedBox(height: 12),

              _MenuItemButton(
                icon: Icons.shopping_cart_outlined,
                label: 'Buy AI credits',
                isHighlight: true,
                onTap: () {
                  Navigator.pop(context);
                  if (context.mounted) {
                    context.go(AppRouter.buyCredits);
                  }
                },
              ),
              const SizedBox(height: 12),
              Divider(height: 0, color: colors.divider),
              const SizedBox(height: 8),

              _MenuItemButton(
                icon: Icons.logout_rounded,
                label: 'Sign out of Zedu users',
                isError: true,
                onTap: () async {
                  Navigator.pop(context);
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
