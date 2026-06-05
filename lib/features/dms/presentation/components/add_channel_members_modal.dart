import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class AddChannelMembersModal extends ConsumerStatefulWidget {
  final Channel channel;
  final DmConversation conversation;

  const AddChannelMembersModal({
    super.key,
    required this.channel,
    required this.conversation,
  });

  @override
  ConsumerState<AddChannelMembersModal> createState() =>
      _AddChannelMembersModalState();
}

class _AddChannelMembersModalState
    extends ConsumerState<AddChannelMembersModal> {
  final _searchController = TextEditingController();
  final List<TeamMember> _selectedMembers = [];
  List<TeamMember> _availableUsers = [];
  List<TeamMember> _filteredUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  void _loadUsers() {
    final teamMembers = ref.read(userProfileNotifierProvider).teamMembers;
    // Exclude users already in the channel
    final existingUserIds = widget.conversation.participants
        .map((p) => p.userId)
        .toSet();

    setState(() {
      _availableUsers = teamMembers
          .where((m) => !existingUserIds.contains(m.id))
          .toList();
    });
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _filteredUsers = []);
      return;
    }
    setState(() {
      _filteredUsers = _availableUsers.where((u) {
        final email = (u.email).toLowerCase();
        final name = (u.name ?? '').toLowerCase();
        final q = query.toLowerCase();
        return email.contains(q) || name.contains(q);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addMember(TeamMember member) {
    if (!_selectedMembers.any((m) => m.id == member.id)) {
      setState(() {
        _selectedMembers.add(member);
        _filteredUsers = [];
        _searchController.clear();
      });
    }
  }

  void _removeMember(String id) {
    setState(() {
      _selectedMembers.removeWhere((m) => m.id == id);
    });
  }

  Future<void> _submit() async {
    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one member.'),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userIds = _selectedMembers.map((m) => m.id).toList();
      bool success = false;

      if (widget.conversation.channelType == 'group_dm') {
        success = await ref
            .read(groupDmProvider.notifier)
            .addGroupDmParticipants(widget.channel.id, userIds);
      } else {
        success = await ref
            .read(channelProvider.notifier)
            .addChannelMembers(widget.channel.id, userIds);
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully added ${_selectedMembers.length} member(s).',
            ),
            backgroundColor: context.colors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to add members.'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add members: $e'),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: colors.background,
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add people to #${widget.channel.name}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colors.textHint),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Search by name or email',
              style: TextStyle(
                fontSize: 14,
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ..._selectedMembers.map(
                    (member) => Chip(
                      label: Text(member.name ?? member.email),
                      labelStyle: TextStyle(
                        fontSize: 13,
                        color: colors.textPrimary,
                      ),
                      backgroundColor: colors.background,
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeMember(member.id),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: colors.divider),
                      ),
                    ),
                  ),
                  IntrinsicWidth(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: _selectedMembers.isEmpty
                            ? '|Enter name or email'
                            : '',
                        hintStyle: TextStyle(
                          color: colors.textHint.withValues(alpha: 0.7),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ],
              ),
            ),
            if (_filteredUsers.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: const BoxConstraints(maxHeight: 150),
                child: Material(
                  color: colors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(color: colors.divider),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return ListTile(
                        title: Text(
                          user.name ?? 'Unknown',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          user.email,
                          style: TextStyle(
                            color: colors.textHint,
                            fontSize: 11,
                          ),
                        ),
                        onTap: () => _addMember(user),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Divider(color: colors.divider.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    disabledBackgroundColor: colors.primary.withValues(
                      alpha: 0.5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.onPrimary,
                            ),
                          ),
                        )
                      : const Text(
                          'Add Members',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
