import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class UserProfileView extends ConsumerWidget {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<UserProfileState>(userProfileNotifierProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        AppToastService.show(
          context,
          type: AppToastType.error,
          message: next.error!,
        );
      }
      if (next.successMessage != null &&
          previous?.successMessage != next.successMessage) {
        AppToastService.show(
          context,
          type: AppToastType.success,
          message: next.successMessage!,
        );
      }
    });

    final state = ref.watch(userProfileNotifierProvider);
    final notifier = ref.read(userProfileNotifierProvider.notifier);

    return ProfileSettingsShell(
      selectedSection: state.section,
      onSectionSelected: notifier.selectSection,
      child: _ProfileContent(state: state, notifier: notifier),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: context.colors.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load profile data',
            style: context.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: context.textTheme.bodySmall?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(label: 'Retry', expand: false, onPressed: onRetry),
        ],
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.state, required this.notifier});

  final UserProfileState state;
  final UserProfileNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 32, 40, 48),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: switch (state.section) {
            UserProfileSection.account => AccountSection(
              account: state.account ?? ProfileAccount.empty(),
              isSaving: state.isSaving,
              onSave: notifier.updateAccount,
              onDelete: notifier.deleteAccount,
            ),
            UserProfileSection.notifications => NotificationsSection(
              preferences:
                  state.notifications ?? NotificationPreferences.empty(),
              isSaving: state.isSaving,
              onSave: notifier.updateNotificationPreferences,
            ),
            UserProfileSection.security => SecuritySection(
              sessions: state.securitySessions,
              isSaving: state.isSaving,
              onChangePassword: notifier.changePassword,
            ),
            UserProfileSection.organization => OrganizationSection(
              organization: state.organization ?? OrganizationProfile.empty(),
              isSaving: state.isSaving,
              onSave: notifier.updateOrganization,
              onDelete: notifier.deleteOrganization,
            ),
            UserProfileSection.userManagement => UserManagementSection(
              members: state.teamMembers,
              isSaving: state.isSaving,
              onInvite: notifier.inviteMember,
              onUpdate: notifier.updateMember,
              onRemove: notifier.removeMember,
            ),
            UserProfileSection.rolesAndPermissions =>
              RolesAndPermissionsSection(roles: state.rolesAndPermissions),
            UserProfileSection.billing => BillingSection(
              billing: state.billing ?? BillingInfo.empty(),
            ),
          },
        ),
      ),
    );
  }
}
