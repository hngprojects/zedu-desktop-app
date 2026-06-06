import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class UserManagementSection extends StatefulWidget {
  const UserManagementSection({
    super.key,
    required this.members,
    required this.isSaving,
    required this.onInvite,
    required this.onUpdate,
    required this.onRemove,
    required this.onAddUser,
    required this.onFetchUsers,
  });

  final List<TeamMember> members;
  final bool isSaving;
  final Future<void> Function({required String email, required String role})
  onInvite;
  final ValueChanged<TeamMember> onUpdate;
  final ValueChanged<String> onRemove;
  final Future<void> Function({required String userId, required String email})
  onAddUser;
  final Future<List<Map<String, dynamic>>> Function() onFetchUsers;

  @override
  State<UserManagementSection> createState() => _UserManagementSectionState();
}

class _UserManagementSectionState extends State<UserManagementSection> {
  final _searchController = TextEditingController();
  String _roleFilter = 'All Roles';
  String _activeTab = 'Members';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseList = widget.members.where((member) {
      if (_activeTab == 'Members') {
        return member.status != TeamMemberStatus.pending;
      } else {
        return member.status == TeamMemberStatus.pending;
      }
    }).toList();

    final query = _searchController.text.trim().toLowerCase();
    final filtered = baseList.where((member) {
      final matchesQuery =
          query.isEmpty || member.email.toLowerCase().contains(query);
      final matchesRole =
          _roleFilter == 'All Roles' || member.role == _roleFilter;
      return matchesQuery && matchesRole;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          title: 'Your Team',
          subtitle: 'Manage all members of your team.',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton.outlined(
                label: 'Add User',
                expand: false,
                height: 44,
                onPressed: () => _showAddUserDialog(context),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'Invite People',
                expand: false,
                height: 44,
                loading: widget.isSaving,
                onPressed: () => _showInviteDialog(context, widget.onInvite),
              ),
            ],
          ),
        ),
        const SizedBox(height: 34),
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _activeTab = 'Members'),
              behavior: HitTestBehavior.opaque,
              child: _TabLabel(
                label: 'Members',
                count: widget.members
                    .where((m) => m.status != TeamMemberStatus.pending)
                    .length,
                active: _activeTab == 'Members',
              ),
            ),
            const SizedBox(width: 32),
            GestureDetector(
              onTap: () => setState(() => _activeTab = 'Invites'),
              behavior: HitTestBehavior.opaque,
              child: _TabLabel(
                label: 'Invites',
                count: widget.members
                    .where((m) => m.status == TeamMemberStatus.pending)
                    .length,
                active: _activeTab == 'Invites',
              ),
            ),
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
                      value: _roleFilter,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'All Roles',
                          child: Text('All Roles'),
                        ),
                        DropdownMenuItem(
                          value: 'Administrator',
                          child: Text('Administrator'),
                        ),
                        DropdownMenuItem(
                          value: 'Manager',
                          child: Text('Manager'),
                        ),
                        DropdownMenuItem(value: 'User', child: Text('User')),
                      ],
                      onChanged: (value) => setState(() {
                        _roleFilter = value ?? 'All Roles';
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
                    columns: [
                      const DataColumn(label: Text('Email Address')),
                      const DataColumn(label: Text('Role')),
                      DataColumn(
                        label: Text(
                          _activeTab == 'Members' ? 'Date Joined' : 'Sent At',
                        ),
                      ),
                      const DataColumn(label: Text('Status')),
                      const DataColumn(label: Text('Actions')),
                    ],
                    rows: filtered.map((member) {
                      return DataRow(
                        cells: [
                          DataCell(_MemberIdentity(email: member.email)),
                          DataCell(Text(member.role)),
                          DataCell(Text(member.dateJoined)),
                          DataCell(
                            ProfileStatusPill(status: member.status.name),
                          ),
                          DataCell(
                            Row(
                              children: [
                                SquareIconButton(
                                  icon: Icons.edit_outlined,
                                  size: 28,
                                  onTap: () => _showMemberDialog(
                                    context,
                                    member,
                                    widget.onUpdate,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SquareIconButton(
                                  icon: Icons.delete_outline,
                                  size: 28,
                                  onTap: () => _confirmRemove(
                                    context,
                                    member.email,
                                    () async => widget.onRemove(member.id),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const AppButton.outlined(
                      label: 'Previous',
                      expand: false,
                      height: 36,
                      disabled: true,
                    ),
                    const Spacer(),
                    Text('1', style: context.textTheme.bodySmall),
                    const Spacer(),
                    const AppButton.outlined(
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

  void _showInviteDialog(
    BuildContext context,
    Future<void> Function({required String email, required String role})
    onInvite,
  ) => showInviteMemberDialog(context, onInvite);

  void _showAddUserDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _AddUserDialog(
        onFetchUsers: widget.onFetchUsers,
        existingEmails: widget.members.map((m) => m.email).toSet(),
        onAddUser: (userId, email) async {
          Navigator.pop(ctx);
          await widget.onAddUser(userId: userId, email: email);
        },
      ),
    );
  }

  void _showMemberDialog(
    BuildContext context,
    TeamMember member,
    ValueChanged<TeamMember> onUpdate,
  ) => showEditMemberDialog(context, member, onUpdate);

  Future<void> _confirmRemove(
    BuildContext context,
    String email,
    Future<void> Function() onConfirm,
  ) => showProfileConfirmDialog(
    context,
    title: 'Remove team member?',
    message: '$email will lose access to this organization.',
    confirmLabel: 'Remove member',
    onConfirm: onConfirm,
    destructive: true,
  );
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
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? context.colors.sidebar
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFE9E9FF)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: context.textTheme.labelSmall?.copyWith(
                  color: active
                      ? context.colors.sidebar
                      : const Color(0xFF6B7280),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        if (active) ...[
          const SizedBox(height: 8),
          Container(height: 2, width: 80, color: context.colors.sidebar),
        ],
      ],
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
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFE9FBFA),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.person, size: 18, color: Color(0xFF17C9BD)),
          ),
        ),
        const SizedBox(width: 12),
        Text(email, style: context.textTheme.bodyMedium),
      ],
    );
  }
}

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog({
    required this.onFetchUsers,
    required this.existingEmails,
    required this.onAddUser,
  });

  final Future<List<Map<String, dynamic>>> Function() onFetchUsers;
  final Set<String> existingEmails;
  final Future<void> Function(String userId, String email) onAddUser;

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await widget.onFetchUsers();
    if (mounted) {
      setState(() {
        _allUsers = users;
        _isLoadingUsers = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _filteredUsers = []);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((u) {
        final email = (u['email'] as String?)?.toLowerCase() ?? '';
        final name =
            (u['full_name'] as String?)?.toLowerCase() ??
            (u['username'] as String?)?.toLowerCase() ??
            '';
        // Exclude users already in the org
        if (widget.existingEmails.contains(u['email'] as String? ?? '')) {
          return false;
        }
        return email.contains(q) || name.contains(q);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Add Existing User',
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search for users already on Zedu and add them directly.',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textHint,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
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
            const SizedBox(height: 8),
            if (_isLoadingUsers)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_searchController.text.isNotEmpty &&
                _filteredUsers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No users found.',
                    style: TextStyle(color: colors.textHint),
                  ),
                ),
              )
            else if (_filteredUsers.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    final email = user['email'] as String? ?? '';
                    final name =
                        user['full_name'] as String? ??
                        user['username'] as String? ??
                        email.split('@').first;
                    final userId =
                        user['id'] as String? ??
                        user['user_id'] as String? ??
                        user['uuid'] as String? ??
                        '';
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: colors.primary.withValues(alpha: 0.1),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        email,
                        style: TextStyle(color: colors.textHint, fontSize: 12),
                      ),
                      trailing: TextButton(
                        onPressed: () => widget.onAddUser(userId, email),
                        child: const Text('Add'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
