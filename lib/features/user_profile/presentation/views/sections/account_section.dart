import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class AccountSection extends ConsumerWidget {
  const AccountSection({
    super.key,
    required this.account,
    required this.isSaving,
    required this.onSave,
    required this.onDelete,
  });

  final ProfileAccount account;
  final bool isSaving;
  final ValueChanged<ProfileAccount> onSave;
  final Future<void> Function(String password) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionHeader(
          title: 'Your Account Information',
          subtitle: 'Manage your account data with ease.',
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    // Reactive avatar — shows local preview + server URL
                    const UserAvatar(size: 160, borderRadius: 8),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: SquareIconButton(
                        icon: Icons.edit_outlined,
                        onTap: () =>
                            _showAccountDialog(context, account, onSave),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const ProfileFieldLabel('Name'),
                const SizedBox(height: 4),
                Text(
                  account.name,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  account.username.isNotEmpty
                      ? (account.username.startsWith('@')
                            ? account.username
                            : '@${account.username}')
                      : '@${account.name.replaceAll(' ', '').toLowerCase()}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 48),
            Expanded(
              child: ProfileCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ProfileFieldLabel('Email Address'),
                    const SizedBox(height: 8),
                    Text(account.email, style: context.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        AppButton.outlined(
          label: 'Delete my account',
          expand: false,
          height: 44,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFEF4444),
            side: const BorderSide(color: Color(0xFFEF4444)),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          loading: isSaving,
          onPressed: () =>
              showDeleteAccountDialog(context, account.email, (password) async {
                await onDelete(password);
                if (context.mounted) {
                  final hasError =
                      ref.read(userProfileNotifierProvider).error != null;
                  if (!hasError) {
                    ref.read(authNotifierProvider.notifier).logout();
                  }
                }
              }),
        ),
      ],
    );
  }

  void _showAccountDialog(
    BuildContext context,
    ProfileAccount account,
    ValueChanged<ProfileAccount> onSave,
  ) => showEditAccountDialog(context, account, onSave);
}
