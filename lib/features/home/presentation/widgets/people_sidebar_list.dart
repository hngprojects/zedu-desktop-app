import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import 'package:zedu/features/home/presentation/providers/org_people_provider.dart';

class PeopleSidebarList extends ConsumerStatefulWidget {
  const PeopleSidebarList({super.key});

  @override
  ConsumerState<PeopleSidebarList> createState() => _PeopleSidebarListState();
}

class _PeopleSidebarListState extends ConsumerState<PeopleSidebarList> {
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 320,
      color: colors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceSwitcherHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            child: _SearchBar(
              controller: _searchController,
              onChanged: (val) => setState(() => _query = val.toLowerCase()),
              colors: colors,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'People',
              style: TextStyle(
                color: colors.onPrimary.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(child: _PeopleList(query: _query)),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final AppPalette colors;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: colors.onPrimary.withValues(alpha: 0.68)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(Icons.search, color: colors.onPrimary.withValues(alpha: 0.9), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                color: colors.onPrimary.withValues(alpha: 0.9),
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Search people',
                hintStyle: TextStyle(
                  color: colors.onPrimary.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.only(bottom: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeopleList extends ConsumerWidget {
  final String query;

  const _PeopleList({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentUserId = ref.watch(authNotifierProvider).user?.id;
    final peopleState = ref.watch(userProfileNotifierProvider);

    if (peopleState.isLoading && peopleState.teamMembers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final members = peopleState.teamMembers;

    final filtered = query.isEmpty
        ? members
        : members.where((m) {
            final name = (m.name ?? '').toLowerCase();
            final email = m.email.toLowerCase();
            return name.contains(query) || email.contains(query);
          }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No members found',
          style: TextStyle(color: colors.onPrimary.withValues(alpha: 0.5)),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: filtered.length,
      itemBuilder: (context, index) => _PeopleTile(
        member: filtered[index],
        isCurrentUser: filtered[index].id == currentUserId,
      ),
    );
  }
}

class _PeopleTile extends ConsumerStatefulWidget {
  final TeamMember member;
  final bool isCurrentUser;

  const _PeopleTile({required this.member, required this.isCurrentUser});

  @override
  ConsumerState<_PeopleTile> createState() => _PeopleTileState();
}

class _PeopleTileState extends ConsumerState<_PeopleTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final m = widget.member;
    final initials = (m.name?.isNotEmpty == true)
        ? m.name![0].toUpperCase()
        : m.email[0].toUpperCase();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => DmSidebarList.openOrCreateDm(
          context: context,
          ref: ref,
          memberId: m.id,
          memberName: m.name ?? 'Unknown',
          memberEmail: m.email,
          memberAvatarUrl: m.avatarUrl,
          isSelf: widget.isCurrentUser,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          color: _hovered
              ? colors.onPrimary.withValues(alpha: 0.07)
              : Colors.transparent,
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isCurrentUser
                          ? '${m.name ?? m.email} (You)'
                          : (m.name ?? m.email),
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      m.email,
                      style: TextStyle(
                        color: colors.onPrimary.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // "Message" hint on hover
              if (_hovered)
                Tooltip(
                  message: 'Send message',
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: colors.onPrimary.withValues(alpha: 0.6),
                  ),
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
