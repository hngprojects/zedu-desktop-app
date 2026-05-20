import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class WorkspaceSwitcherList extends ConsumerWidget {
  const WorkspaceSwitcherList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final activeOrg = ref.watch(activeOrganizationProvider);

    if (activeOrg == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors.textPrimary.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentWorkspaceHeader(context, activeOrg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go(
                          AppRouter.organizationSettings(activeOrg.id),
                        );
                      },
                      icon: Icon(
                        Icons.settings_outlined,
                        size: 18,
                        color: colors.textPrimary,
                      ),
                      label: Text(
                        'Settings',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(color: colors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.person_add_alt,
                      label: 'Invite',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Switch Workspaces',
                style: TextStyle(
                  color: colors.textHint,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: 1,
                itemBuilder: (context, index) {
                  return _WorkspaceListItem(
                    org: activeOrg,
                    isActive: true,
                    onTap: () => Navigator.pop(context),
                  );
                },
              ),
            ),
            Divider(height: 1, color: colors.divider),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWorkspaceHeader(
    BuildContext context,
    Organization org,
  ) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          OrganizationLogo(logoUrl: org.logoUrl, name: org.name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  org.name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Current',
            style: TextStyle(
              color: colors.textHint.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        context.go(AppRouter.createOrganization);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.add, color: colors.textHint, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Add a new organization',
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18, color: colors.textPrimary),
      label: Text(
        label,
        style: TextStyle(color: colors.textPrimary, fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        side: BorderSide(color: colors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

class _WorkspaceListItem extends StatelessWidget {
  final Organization org;
  final bool isActive;
  final VoidCallback onTap;

  const _WorkspaceListItem({
    required this.org,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isActive
            ? colors.textPrimary.withValues(alpha: 0.05)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _avatarColor(colors, org.name),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  org.name.isNotEmpty
                      ? org.name.substring(0, 1).toUpperCase()
                      : 'O',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                org.name,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.push_pin,
              size: 16,
              color: isActive
                  ? colors.textHint.withValues(alpha: 0.75)
                  : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Color _avatarColor(AppPalette colors, String name) {
    final palette = [
      colors.accent,
      colors.success,
      colors.primary,
      colors.error,
      colors.borderOutline,
      colors.textSecondary,
    ];
    return palette[name.length % palette.length];
  }
}
