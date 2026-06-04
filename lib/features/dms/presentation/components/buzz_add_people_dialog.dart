import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class BuzzAddPeopleDialog extends ConsumerStatefulWidget {
  final String buzzId;

  const BuzzAddPeopleDialog({super.key, required this.buzzId});

  @override
  ConsumerState<BuzzAddPeopleDialog> createState() =>
      _BuzzAddPeopleDialogState();
}

class _BuzzAddPeopleDialogState extends ConsumerState<BuzzAddPeopleDialog> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _inviteSent = false;

  @override
  void initState() {
    super.initState();
    // Seed suggestions from org people on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orgBuzzProvider.notifier).searchMembers('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    ref.read(orgBuzzProvider.notifier).clearSelection();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      ref.read(orgBuzzProvider.notifier).searchMembers(q);
    });
  }

  Future<void> _sendInvitations() async {
    final ok = await ref.read(orgBuzzProvider.notifier).sendInvitations();
    if (ok && mounted) {
      setState(() => _inviteSent = true);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final buzz = ref.watch(orgBuzzProvider);
    final selectedIds = buzz.selectedMemberIds;
    final results = buzz.searchResults;
    final isSearching = buzz.isSearching;
    final isInviting = buzz.isInviting;

    // Chips for selected members (looked up from search results)
    final selectedMembers = results
        .where((m) => selectedIds.contains(m.id))
        .toList();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  const Text(
                    'Add people',
                    style: TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Invite tab bar (single tab, styled as per Figma) ────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFF6458F5),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_add_outlined,
                          size: 15,
                          color: const Color(0xFF6458F5),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Invite',
                          style: TextStyle(
                            color: Color(0xFF6458F5),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),

            // ── Selected chips ───────────────────────────────────────────
            if (selectedMembers.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                color: Colors.grey.shade50,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: selectedMembers
                      .map(
                        (m) => _MemberChip(
                          name: m.name,
                          onRemove: () => ref
                              .read(orgBuzzProvider.notifier)
                              .toggleMemberSelection(m.id),
                        ),
                      )
                      .toList(),
                ),
              ),

            // ── Search field ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                autofocus: true,
                style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by name',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ── Suggestions label ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text(
                    'Suggestions',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (selectedIds.isNotEmpty) ...[
                    const Spacer(),
                    Text(
                      'Selected ${selectedIds.length}',
                      style: TextStyle(
                        color: const Color(0xFF6458F5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Member list ──────────────────────────────────────────────
            Expanded(
              child: isSearching
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6458F5),
                        strokeWidth: 2,
                      ),
                    )
                  : results.isEmpty
                      ? Center(
                          child: Text(
                            'No members found',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: results.length,
                          itemBuilder: (ctx, i) {
                            final m = results[i];
                            final isSelected = selectedIds.contains(m.id);
                            return _MemberRow(
                              member: m,
                              isSelected: isSelected,
                              onTap: () => ref
                                  .read(orgBuzzProvider.notifier)
                                  .toggleMemberSelection(m.id),
                            );
                          },
                        ),
            ),

            // ── Footer: Send invitation ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _SendButton(
                enabled: selectedIds.isNotEmpty && !isInviting,
                isLoading: isInviting,
                sent: _inviteSent,
                onPressed: _sendInvitations,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _MemberChip extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;

  const _MemberChip({required this.name, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF6458F5).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Color(0xFF6458F5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onRemove,
              child: const Icon(
                Icons.close,
                size: 14,
                color: Color(0xFF6458F5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatefulWidget {
  final BuzzMember member;
  final bool isSelected;
  final VoidCallback onTap;

  const _MemberRow({
    required this.member,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_MemberRow> createState() => _MemberRowState();
}

class _MemberRowState extends State<_MemberRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final initials = m.name.isNotEmpty ? m.name[0].toUpperCase() : '?';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: _hovered ? Colors.grey.shade50 : Colors.transparent,
          child: Row(
            children: [
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _avatarColor(m.id),
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: m.avatarUrl != null && m.avatarUrl!.isNotEmpty
                    ? Image.network(
                        m.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // Name + role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (m.role != null && m.role!.isNotEmpty)
                      Text(
                        m.role!,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),

              // Selection indicator (radio style)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isSelected
                        ? const Color(0xFF6458F5)
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                  color: widget.isSelected
                      ? const Color(0xFF6458F5)
                      : Colors.transparent,
                ),
                child: widget.isSelected
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _avatarColor(String id) {
    const palette = [
      Color(0xFF7C3AED),
      Color(0xFF2563EB),
      Color(0xFF059669),
      Color(0xFFD97706),
      Color(0xFFDC2626),
      Color(0xFF0891B2),
    ];
    return palette[id.hashCode.abs() % palette.length];
  }
}

class _SendButton extends StatefulWidget {
  final bool enabled;
  final bool isLoading;
  final bool sent;
  final VoidCallback onPressed;

  const _SendButton({
    required this.enabled,
    required this.isLoading,
    required this.sent,
    required this.onPressed,
  });

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && !widget.isLoading && !widget.sent;

    return MouseRegion(
      cursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: active ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: widget.sent
                ? Colors.green.shade600
                : active
                    ? (_hovered
                          ? const Color(0xFF5A4DE0)
                          : const Color(0xFF6458F5))
                    : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.sent ? '✓ Invitation sent' : 'Send invitation',
                    style: TextStyle(
                      color: active || widget.sent
                          ? Colors.white
                          : Colors.grey.shade500,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
