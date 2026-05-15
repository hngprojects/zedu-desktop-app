import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class WorkspaceSidebarSection extends StatelessWidget {
  const WorkspaceSidebarSection({
    required this.category,
    required this.isCollapsed,
    required this.selectedItemId,
    required this.onToggle,
    required this.onItemSelected,
    super.key,
  });

  final WorkspaceCategory category;
  final bool isCollapsed;
  final String selectedItemId;
  final VoidCallback onToggle;
  final ValueChanged<String> onItemSelected;

  bool get _isChannels => category.title.toLowerCase() == 'channels';
  bool get _isPeople => category.title.toLowerCase() == 'people';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.only(bottom: 8),
      child: Column(
        children: [
          _SectionHeader(
            category: category,
            isCollapsed: isCollapsed,
            onToggle: onToggle,
          ),
          if (!isCollapsed) ...[
            if (category.items.isEmpty)
              _EmptyCategoryState(
                message: _isPeople
                    ? 'No recent chats. Start a new conversation!'
                    : 'No items available',
              )
            else
              ...category.items.map(
                (item) => _WorkspaceSidebarItem(
                  item: item,
                  isSelected: item.id == selectedItemId,
                  onTap: () => onItemSelected(item.id),
                ),
              ),
            if (_isChannels)
              const _SidebarActionButton(title: 'View all channels'),
            if (_isPeople) const _SidebarActionButton(title: 'View all people'),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.category,
    required this.isCollapsed,
    required this.onToggle,
  });

  final WorkspaceCategory category;
  final bool isCollapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: context.only(left: 16, right: 16, top: 6, bottom: 6),
        child: Row(
          children: [
            Icon(
              isCollapsed
                  ? Icons.keyboard_arrow_right_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: colors.background.withValues(alpha: 0.65),
              size: context.s(16),
            ),
            context.gapH(4),
            Expanded(
              child: Text(
                category.title,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.background.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceSidebarItem extends StatelessWidget {
  const _WorkspaceSidebarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final WorkspaceItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isChannel = item.type == WorkspaceItemType.channel;

    return Container(
      constraints: BoxConstraints(minHeight: context.s(28)),
      margin: context.only(left: 16, right: 16, bottom: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? colors.background.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(context.s(6)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.s(6)),
        child: Padding(
          padding: context.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            children: [
              if (isChannel)
                Text(
                  '#',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.background.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                CircleAvatar(
                  radius: context.s(10),
                  backgroundColor: colors.background,
                  child: Icon(
                    Icons.person,
                    size: context.s(13),
                    color: colors.primary,
                  ),
                ),
              context.gapH(10),
              Expanded(
                child: Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.background.withValues(alpha: 0.75),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarActionButton extends StatelessWidget {
  const _SidebarActionButton({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: context.only(left: 16, right: 16, top: 4, bottom: 8),
      child: Container(
        height: context.s(32),
        padding: context.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: colors.background.withValues(alpha: 0.02),
          border: Border.all(
            color: colors.borderOutline.withValues(alpha: 0.65),
            width: context.s(1),
          ),
          borderRadius: BorderRadius.circular(context.s(6)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: context.textTheme.labelMedium?.copyWith(
                  color: colors.background.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: context.s(16),
              color: colors.background.withValues(alpha: 0.65),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCategoryState extends StatelessWidget {
  const _EmptyCategoryState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: context.only(left: 40, right: 16, top: 2, bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          message,
          style: context.textTheme.labelSmall?.copyWith(
            color: colors.background.withValues(alpha: 0.45),
            fontSize: context.s(9),
          ),
        ),
      ),
    );
  }
}
