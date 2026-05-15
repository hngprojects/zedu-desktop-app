import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class WorkspaceSidebar extends ConsumerWidget {
  const WorkspaceSidebar({super.key});

  static const double _iconRailWidth = 61;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final workspaceState = ref.watch(workspaceProvider);
    final workspaceNotifier = ref.read(workspaceProvider.notifier);

    return Row(
      children: [
        const _SidebarIconRail(),
        Expanded(
          child: Container(
            color: colors.primary,
            child: ListView(
              padding: context.only(top: 16),
              children: [
                const _SidebarHeader(),
                context.gapV(14),
                ...workspaceState.categories.map(
                  (category) => WorkspaceSidebarSection(
                    category: category,
                    isCollapsed: workspaceState.isCategoryCollapsed(
                      category.id,
                    ),
                    selectedItemId: workspaceState.selectedItemId,
                    onToggle: () =>
                        workspaceNotifier.toggleCategory(category.id),
                    onItemSelected: workspaceNotifier.selectItem,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SidebarIconRail extends StatelessWidget {
  const _SidebarIconRail();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: context.s(WorkspaceSidebar._iconRailWidth),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.9),
        border: Border(
          right: BorderSide(
            color: colors.primary.withValues(alpha: 0.65),
            width: context.s(4),
          ),
        ),
      ),
      child: Column(
        children: [
          context.gapV(12),
          const _RailItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isActive: true,
          ),
          const _RailItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'DMs',
          ),
          const _RailItem(icon: Icons.person_outline_rounded, label: 'People'),
          const _RailItem(
            icon: Icons.insert_drive_file_outlined,
            label: 'Files',
          ),
          const _RailItem(icon: Icons.call_outlined, label: 'Buzz'),
          const Spacer(),
          const _RailItem(
            icon: Icons.notifications_none_rounded,
            label: '',
            showNotification: true,
          ),
          const _RailItem(icon: Icons.settings_outlined, label: ''),
          context.gapV(10),
          const _ProfileAvatar(),
          context.gapV(10),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: context.symmetric(horizontal: 16),
      child: SizedBox(
        height: context.s(32),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Anonymoususer',
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.background,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  context.gapH(4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: context.s(14),
                    color: colors.background.withValues(alpha: 0.65),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_rounded,
              size: context.s(20),
              color: colors.background,
            ),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.showNotification = false,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final bool showNotification;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasLabel = label.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: context.s(50),
          margin: context.symmetric(vertical: 3, horizontal: 5),
          padding: context.symmetric(vertical: hasLabel ? 7 : 8),
          decoration: BoxDecoration(
            color: isActive
                ? colors.background.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(context.s(8)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: context.s(18),
                color: colors.background.withValues(alpha: 0.95),
              ),
              if (hasLabel) ...[
                context.gapV(3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.background.withValues(alpha: 0.95),
                    fontSize: context.s(9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (isActive)
          Positioned(
            left: 0,
            child: Container(
              width: context.s(3),
              height: context.s(20),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(context.s(2)),
              ),
            ),
          ),
        if (showNotification)
          Positioned(
            right: context.s(9),
            top: context.s(4),
            child: Container(
              width: context.s(8),
              height: context.s(8),
              decoration: BoxDecoration(
                color: colors.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.primary,
                  width: context.s(1.5),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: context.s(38),
          height: context.s(38),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(context.s(10)),
          ),
          child: Text(
            'AP',
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
              fontSize: context.s(13),
            ),
          ),
        ),
        Container(
          width: context.s(11),
          height: context.s(11),
          decoration: BoxDecoration(
            color: colors.success,
            shape: BoxShape.circle,
            border: Border.all(color: colors.primary, width: context.s(2)),
          ),
        ),
      ],
    );
  }
}
