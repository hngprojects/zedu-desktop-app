import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ProfileSectionContent extends StatelessWidget {
  const ProfileSectionContent({
    super.key,
    required this.state,
    required this.notifier,
  });

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
              onRevert: notifier.revertNotificationPreferences,
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
