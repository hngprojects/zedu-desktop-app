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
      child: state.isLoading
          ? Center(child: CircularProgressIndicator(color: context.colors.primary))
          : _ProfileContent(state: state, notifier: notifier),
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
          constraints: const BoxConstraints(maxWidth: 980),
          child: switch (state.section) {
            UserProfileSection.account => _AccountSection(
              account: state.account!,
              isSaving: state.isSaving,
              onSave: notifier.updateAccount,
              onDelete: notifier.deleteAccount,
            ),
            UserProfileSection.notifications => _NotificationsSection(
              preferences: state.notifications!,
              isSaving: state.isSaving,
              onSave: notifier.updateNotificationPreferences,
            ),
            UserProfileSection.security => _SecuritySection(
              sessions: state.securitySessions,
              isSaving: state.isSaving,
              onChangePassword: notifier.changePassword,
            ),
            UserProfileSection.organization => _OrganizationSection(
              organization: state.organization!,
              isSaving: state.isSaving,
              onSave: notifier.updateOrganization,
              onDelete: notifier.deleteOrganization,
            ),
            UserProfileSection.userManagement => _UserManagementSection(
              members: state.teamMembers,
              isSaving: state.isSaving,
              onInvite: notifier.inviteMember,
              onUpdate: notifier.updateMember,
              onRemove: notifier.removeMember,
            ),
          },
        ),
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.account,
    required this.isSaving,
    required this.onSave,
    required this.onDelete,
  });

  final ProfileAccount account;
  final bool isSaving;
  final ValueChanged<ProfileAccount> onSave;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionHeader(
          title: 'Your Account Information',
          subtitle: 'Manage your account data with ease.',
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            ProfileCard(
              width: 480,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AvatarBlock(initials: account.initials),
                      const SizedBox(height: 18),
                      const _FieldLabel('Name'),
                      Text(
                        '@${account.name.replaceAll(' ', '').toLowerCase()}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel('Timezone'),
                      Text(account.timezone, style: context.textTheme.bodySmall),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _SquareIconButton(
                      icon: Icons.edit_outlined,
                      onTap: () => _showAccountDialog(context, account, onSave),
                    ),
                  ),
                ],
              ),
            ),
            ProfileCard(
              width: 420,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Email Address'),
                  const SizedBox(height: 6),
                  Text(account.email, style: context.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
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
          onPressed: () => _confirm(
            context,
            title: 'Delete account?',
            message:
                'This action cannot be undone. Your account information will be removed.',
            confirmLabel: 'Delete account',
            onConfirm: onDelete,
          ),
        ),
      ],
    );
  }
}

class _NotificationsSection extends StatefulWidget {
  const _NotificationsSection({
    required this.preferences,
    required this.isSaving,
    required this.onSave,
  });

  final NotificationPreferences preferences;
  final bool isSaving;
  final ValueChanged<NotificationPreferences> onSave;

  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  late NotificationPreferences _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.preferences;
  }

  @override
  void didUpdateWidget(covariant _NotificationsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences != widget.preferences) {
      _draft = widget.preferences;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionHeader(
          title: 'Your Notification Preferences',
          subtitle: 'Manage when and why you get notified.',
        ),
        const SizedBox(height: 38),
        _SectionDivider(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Send notifications for:'),
              _RadioLine(
                label: 'All new messages',
                value: NotificationMode.allMessages,
                groupValue: _draft.mode,
                onChanged: (value) => _setDraft(_draft.copyWith(mode: value)),
              ),
              _RadioLine(
                label: 'Mentions',
                value: NotificationMode.mentionsOnly,
                groupValue: _draft.mode,
                onChanged: (value) => _setDraft(_draft.copyWith(mode: value)),
              ),
              _RadioLine(
                label: 'Nothing',
                value: NotificationMode.none,
                groupValue: _draft.mode,
                onChanged: (value) => _setDraft(_draft.copyWith(mode: value)),
              ),
            ],
          ),
        ),
        _SectionDivider(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Receive notifications only within:'),
              const SizedBox(height: 12),
              Row(
                children: [
                  _TimeSelect(
                    label: 'From',
                    value: _draft.fromTime,
                    onChanged: (value) =>
                        _setDraft(_draft.copyWith(fromTime: value)),
                  ),
                  const SizedBox(width: 14),
                  _TimeSelect(
                    label: 'To',
                    value: _draft.toTime,
                    onChanged: (value) =>
                        _setDraft(_draft.copyWith(toTime: value)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  text: 'Note: ',
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    TextSpan(
                      text: 'Outside this time, notifications are paused.',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel('To keep me informed:'),
            _CheckboxLine(
              label: 'Use different settings for mobile devices',
              value: _draft.useDesktopSettings,
              onChanged: (value) =>
                  _setDraft(_draft.copyWith(useDesktopSettings: value)),
            ),
            _CheckboxLine(
              label: 'Receive notifications via email',
              value: _draft.emailNotifications,
              onChanged: (value) =>
                  _setDraft(_draft.copyWith(emailNotifications: value)),
            ),
          ],
        ),
        const SizedBox(height: 56),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppButton.outlined(
              label: 'Revert changes',
              expand: false,
              height: 44,
              onPressed: () => _setDraft(widget.preferences),
            ),
            const SizedBox(width: 16),
            AppButton(
              label: 'Save changes',
              expand: false,
              height: 44,
              loading: widget.isSaving,
              onPressed: () {
                if (!_isValidTimeRange(_draft.fromTime, _draft.toTime)) {
                  AppToastService.show(
                    context,
                    type: AppToastType.error,
                    message: 'Choose a valid notification time range.',
                  );
                  return;
                }
                widget.onSave(_draft);
              },
            ),
          ],
        ),
      ],
    );
  }

  void _setDraft(NotificationPreferences preferences) {
    setState(() {
      _draft = preferences;
    });
  }
}

class _SecuritySection extends StatelessWidget {
  const _SecuritySection({
    required this.sessions,
    required this.isSaving,
    required this.onChangePassword,
  });

  final List<SecuritySession> sessions;
  final bool isSaving;
  final Future<void> Function({
    required String currentPassword,
    required String newPassword,
  })
  onChangePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          title: 'Your Account Security',
          subtitle: 'Keeping your data secure by staying in-the-know',
          trailing: AppButton.outlined(
            label: 'Change password',
            expand: false,
            height: 44,
            loading: isSaving,
            onPressed: () => _showPasswordDialog(context, onChangePassword),
          ),
        ),
        const SizedBox(height: 28),
        _SessionsTable(sessions: sessions),
      ],
    );
  }
}

class _OrganizationSection extends StatelessWidget {
  const _OrganizationSection({
    required this.organization,
    required this.isSaving,
    required this.onSave,
    required this.onDelete,
  });

  final OrganizationProfile organization;
  final bool isSaving;
  final ValueChanged<OrganizationProfile> onSave;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionHeader(
          title: 'Your Organisation Information',
          subtitle: 'Manage your account data with ease.',
        ),
        const SizedBox(height: 20),
        ProfileCard(
          width: 500,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OrganizationAvatar(initials: organization.initials),
                  const SizedBox(height: 20),
                  const _FieldLabel('Name'),
                  Text(organization.name, style: context.textTheme.bodySmall),
                  const SizedBox(height: 16),
                  const _FieldLabel('Nature of business'),
                  Text(
                    organization.natureOfBusiness,
                    style: context.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Country'),
                  Text(organization.country, style: context.textTheme.bodySmall),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: _SquareIconButton(
                  icon: Icons.edit_outlined,
                  onTap: () => _showOrganizationDialog(
                    context,
                    organization,
                    onSave,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
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
          onPressed: () => _confirm(
            context,
            title: 'Delete organization?',
            message:
                'This will remove the organization and its related workspace data.',
            confirmLabel: 'Delete organization',
            onConfirm: onDelete,
          ),
        ),
      ],
    );
  }
}

class _UserManagementSection extends StatefulWidget {
  const _UserManagementSection({
    required this.members,
    required this.isSaving,
    required this.onInvite,
    required this.onUpdate,
    required this.onRemove,
  });

  final List<TeamMember> members;
  final bool isSaving;
  final Future<void> Function({required String email, required String role})
  onInvite;
  final ValueChanged<TeamMember> onUpdate;
  final ValueChanged<String> onRemove;

  @override
  State<_UserManagementSection> createState() => _UserManagementSectionState();
}

class _UserManagementSectionState extends State<_UserManagementSection> {
  final _searchController = TextEditingController();
  String _role = 'All Roles';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.members.where((member) {
      final matchesQuery =
          query.isEmpty || member.email.toLowerCase().contains(query);
      final matchesRole = _role == 'All Roles' || member.role == _role;
      return matchesQuery && matchesRole;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          title: 'Your Team',
          subtitle: 'Manage all members of your team.',
          trailing: AppButton(
            label: 'Invite People',
            expand: false,
            height: 44,
            loading: widget.isSaving,
            onPressed: () => _showInviteDialog(context, widget.onInvite),
          ),
        ),
        const SizedBox(height: 34),
        Row(
          children: [
            _TabLabel(label: 'Members', count: widget.members.length, active: true),
            const SizedBox(width: 32),
            const _TabLabel(label: 'Invites', count: 1, active: false),
          ],
        ),
        const SizedBox(height: 24),
        ProfileCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search by name or email',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _role,
                      items: const [
                        DropdownMenuItem(
                          value: 'All Roles',
                          child: Text('All Roles'),
                        ),
                        DropdownMenuItem(
                          value: 'Administrator',
                          child: Text('Administrator'),
                        ),
                        DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                        DropdownMenuItem(value: 'User', child: Text('User')),
                      ],
                      onChanged: (value) => setState(() {
                        _role = value ?? 'All Roles';
                      }),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 880,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFFAFAFA),
                    ),
                    columns: const [
                      DataColumn(label: Text('Email Address')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Date Joined')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: [
                      for (final member in filtered)
                        DataRow(
                          cells: [
                            DataCell(_MemberIdentity(email: member.email)),
                            DataCell(Text(member.role)),
                            DataCell(Text(member.dateJoined)),
                            DataCell(_StatusPill(status: member.status)),
                            DataCell(
                              Row(
                                children: [
                                  _SmallActionButton(
                                    icon: Icons.edit_outlined,
                                    onTap: () => _showMemberDialog(
                                      context,
                                      member,
                                      widget.onUpdate,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _SmallActionButton(
                                    icon: Icons.delete_outline,
                                    onTap: () => _confirm(
                                      context,
                                      title: 'Remove team member?',
                                      message:
                                          '${member.email} will lose access to this organization.',
                                      confirmLabel: 'Remove member',
                                      onConfirm: () async =>
                                          widget.onRemove(member.id),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    AppButton.outlined(
                      label: 'Previous',
                      expand: false,
                      height: 36,
                      disabled: true,
                    ),
                    const Spacer(),
                    Text('1', style: context.textTheme.bodySmall),
                    const Spacer(),
                    AppButton.outlined(
                      label: 'Next',
                      expand: false,
                      height: 36,
                      disabled: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarBlock extends StatelessWidget {
  const _AvatarBlock({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 144,
      decoration: BoxDecoration(
        color: const Color(0xFFE9FBFA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Semantics(
        label: initials,
        child: const Icon(Icons.person, size: 116, color: Color(0xFF17C9BD)),
      ),
    );
  }
}

class _OrganizationAvatar extends StatelessWidget {
  const _OrganizationAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 144,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        initials,
        style: context.textTheme.displaySmall?.copyWith(
          color: context.colors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.textTheme.bodySmall?.copyWith(
        color: const Color(0xFF6B7280),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 24, top: 4),
      margin: const EdgeInsets.only(bottom: 22),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: child,
    );
  }
}

class _RadioLine extends StatelessWidget {
  const _RadioLine({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final NotificationMode value;
  final NotificationMode groupValue;
  final ValueChanged<NotificationMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          Radio<NotificationMode>(
            value: value,
            groupValue: groupValue,
            visualDensity: VisualDensity.compact,
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
          Text(label, style: context.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CheckboxLine extends StatelessWidget {
  const _CheckboxLine({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          Checkbox(
            value: value,
            visualDensity: VisualDensity.compact,
            onChanged: (value) => onChanged(value ?? false),
          ),
          Text(label, style: context.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TimeSelect extends StatelessWidget {
  const _TimeSelect({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: value,
            isDense: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
            ),
            items: _timeOptions
                .map((time) => DropdownMenuItem(value: time, child: Text(time)))
                .toList(),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

class _SessionsTable extends StatelessWidget {
  const _SessionsTable({required this.sessions});

  final List<SecuritySession> sessions;

  @override
  Widget build(BuildContext context) {
    final rows = sessions.isEmpty
        ? <SecuritySession>[]
        : sessions.length < 10
        ? [
            ...sessions,
            ...List.generate(
              9 - sessions.length,
              (index) => sessions[index % sessions.length],
            ),
          ]
        : sessions;
    return ProfileCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 920,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFFAFAFA)),
            columns: const [
              DataColumn(label: Text('Device')),
              DataColumn(label: Text('Location')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Last active')),
              DataColumn(label: Text('Status')),
            ],
            rows: [
              for (final session in rows)
                DataRow(
                  cells: [
                    DataCell(Text(session.device)),
                    DataCell(Text(session.location)),
                    DataCell(Text(session.date)),
                    DataCell(Text(session.lastActive)),
                    DataCell(Text(session.status)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.count,
    required this.active,
  });

  final String label;
  final int count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: active ? context.colors.primary : Colors.transparent,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(label, style: context.textTheme.bodyMedium),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 10,
            backgroundColor: const Color(0xFFEDEBFF),
            child: Text('$count', style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _MemberIdentity extends StatelessWidget {
  const _MemberIdentity({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFE9FBFA),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.person, color: Color(0xFF17C9BD), size: 22),
        ),
        const SizedBox(width: 12),
        Text(email),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final TeamMemberStatus status;

  @override
  Widget build(BuildContext context) {
    final text = switch (status) {
      TeamMemberStatus.active => 'Active',
      TeamMemberStatus.pending => 'Pending',
      TeamMemberStatus.inactive => 'Inactive',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFFF5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(text, style: context.textTheme.bodySmall),
        ],
      ),
    );
  }
}

Future<void> _showAccountDialog(
  BuildContext context,
  ProfileAccount account,
  ValueChanged<ProfileAccount> onSave,
) {
  final name = TextEditingController(text: account.name);
  final email = TextEditingController(text: account.email);
  var timezone = account.timezone;

  return _showFormDialog(
    context,
    title: 'Edit account information',
    fields: [
      AppTextField(controller: name, hint: 'Name', label: 'Name'),
      const SizedBox(height: 14),
      AppTextField(
        controller: email,
        hint: 'Email address',
        label: 'Email Address',
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 14),
      StatefulBuilder(
        builder: (context, setState) {
          return DropdownButtonFormField<String>(
            value: timezone,
            decoration: const InputDecoration(labelText: 'Timezone'),
            items: const [
              DropdownMenuItem(value: 'Africa/Lagos', child: Text('Africa/Lagos')),
              DropdownMenuItem(value: 'UTC', child: Text('UTC')),
              DropdownMenuItem(
                value: 'America/New_York',
                child: Text('America/New_York'),
              ),
              DropdownMenuItem(value: 'Europe/London', child: Text('Europe/London')),
            ],
            onChanged: (value) => setState(() {
              timezone = value ?? timezone;
            }),
          );
        },
      ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: () => AppToastService.show(
          context,
          type: AppToastType.info,
          message: 'Profile picture upload will use the backend upload endpoint.',
        ),
        icon: const Icon(Icons.upload_outlined),
        label: const Text('Upload profile picture'),
      ),
    ],
    onSubmit: () {
      if (!_isEmail(email.text)) {
        AppToastService.show(
          context,
          type: AppToastType.error,
          message: 'Enter a valid email address.',
        );
        return false;
      }
      onSave(
        account.copyWith(
          name: name.text.trim(),
          email: email.text.trim(),
          timezone: timezone,
        ),
      );
      return true;
    },
  );
}

Future<void> _showPasswordDialog(
  BuildContext context,
  Future<void> Function({
    required String currentPassword,
    required String newPassword,
  })
  onSubmit,
) {
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();

  return _showFormDialog(
    context,
    title: 'Change password',
    fields: [
      AppTextField(
        controller: current,
        hint: 'Current password',
        label: 'Current password',
        isPassword: true,
      ),
      const SizedBox(height: 14),
      AppTextField(
        controller: next,
        hint: 'New password',
        label: 'New password',
        isPassword: true,
      ),
      const SizedBox(height: 14),
      AppTextField(
        controller: confirm,
        hint: 'Confirm new password',
        label: 'Confirm new password',
        isPassword: true,
      ),
    ],
    onSubmit: () {
      if (next.text.length < 8) {
        AppToastService.show(
          context,
          type: AppToastType.error,
          message: 'Password must be at least 8 characters.',
        );
        return false;
      }
      if (next.text != confirm.text) {
        AppToastService.show(
          context,
          type: AppToastType.error,
          message: 'New passwords do not match.',
        );
        return false;
      }
      onSubmit(currentPassword: current.text, newPassword: next.text);
      return true;
    },
  );
}

Future<void> _showOrganizationDialog(
  BuildContext context,
  OrganizationProfile organization,
  ValueChanged<OrganizationProfile> onSave,
) {
  final name = TextEditingController(text: organization.name);
  final business = TextEditingController(text: organization.natureOfBusiness);
  final country = TextEditingController(text: organization.country);

  return _showFormDialog(
    context,
    title: 'Edit organization information',
    fields: [
      AppTextField(controller: name, hint: 'Organization name', label: 'Name'),
      const SizedBox(height: 14),
      AppTextField(
        controller: business,
        hint: 'Nature of business',
        label: 'Nature of business',
      ),
      const SizedBox(height: 14),
      AppTextField(controller: country, hint: 'Country', label: 'Country'),
    ],
    onSubmit: () {
      onSave(
        organization.copyWith(
          name: name.text.trim(),
          natureOfBusiness: business.text.trim(),
          country: country.text.trim(),
        ),
      );
      return true;
    },
  );
}

Future<void> _showInviteDialog(
  BuildContext context,
  Future<void> Function({required String email, required String role}) onInvite,
) {
  final email = TextEditingController();
  var role = 'User';

  return _showFormDialog(
    context,
    title: 'Invite people',
    fields: [
      AppTextField(
        controller: email,
        hint: 'Email address',
        label: 'Email Address',
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 14),
      StatefulBuilder(
        builder: (context, setState) {
          return DropdownButtonFormField<String>(
            value: role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: const [
              DropdownMenuItem(value: 'Administrator', child: Text('Administrator')),
              DropdownMenuItem(value: 'Manager', child: Text('Manager')),
              DropdownMenuItem(value: 'User', child: Text('User')),
            ],
            onChanged: (value) => setState(() {
              role = value ?? role;
            }),
          );
        },
      ),
    ],
    onSubmit: () {
      if (!_isEmail(email.text)) {
        AppToastService.show(
          context,
          type: AppToastType.error,
          message: 'Enter a valid email address.',
        );
        return false;
      }
      onInvite(email: email.text.trim(), role: role);
      return true;
    },
  );
}

Future<void> _showMemberDialog(
  BuildContext context,
  TeamMember member,
  ValueChanged<TeamMember> onUpdate,
) {
  final email = TextEditingController(text: member.email);
  var role = member.role;

  return _showFormDialog(
    context,
    title: 'Edit team member',
    fields: [
      AppTextField(controller: email, hint: 'Email address', label: 'Email'),
      const SizedBox(height: 14),
      StatefulBuilder(
        builder: (context, setState) {
          return DropdownButtonFormField<String>(
            value: role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: const [
              DropdownMenuItem(value: 'Administrator', child: Text('Administrator')),
              DropdownMenuItem(value: 'Manager', child: Text('Manager')),
              DropdownMenuItem(value: 'User', child: Text('User')),
            ],
            onChanged: (value) => setState(() {
              role = value ?? role;
            }),
          );
        },
      ),
    ],
    onSubmit: () {
      onUpdate(member.copyWith(email: email.text.trim(), role: role));
      return true;
    },
  );
}

Future<void> _showFormDialog(
  BuildContext context, {
  required String title,
  required List<Widget> fields,
  required bool Function() onSubmit,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(child: Column(children: fields)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (onSubmit()) Navigator.of(context).pop();
            },
            child: const Text('Save changes'),
          ),
        ],
      );
    },
  );
}

Future<void> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required Future<void> Function() onConfirm,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}

bool _isEmail(String value) {
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
}

bool _isValidTimeRange(String from, String to) {
  return _timeOptions.indexOf(from) < _timeOptions.indexOf(to);
}

const _timeOptions = [
  '12:00 AM',
  '1:00 AM',
  '2:00 AM',
  '3:00 AM',
  '4:00 AM',
  '5:00 AM',
  '6:00 AM',
  '7:00 AM',
  '8:00 AM',
  '9:00 AM',
  '10:00 AM',
  '11:00 AM',
  '12:00 PM',
  '1:00 PM',
  '2:00 PM',
  '3:00 PM',
  '4:00 PM',
  '5:00 PM',
  '6:00 PM',
  '7:00 PM',
  '8:00 PM',
  '9:00 PM',
  '10:00 PM',
  '11:00 PM',
];
