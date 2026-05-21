import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MainSidebar extends StatelessWidget {
  const MainSidebar({required this.section, super.key});

  final MenuSection section;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case MenuSection.home:
      case MenuSection.channelsDirectory:
        return const HomeSidebar();
      case MenuSection.dms:
        return const DmsSidebar();
      case MenuSection.people:
        return const PeopleSidebar();
      case MenuSection.files:
        return const FilesSidebar();
      case MenuSection.buzz:
        return const SizedBox.shrink();
    }
  }
}

class HomeSidebar extends ConsumerWidget {
  const HomeSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(channelProvider);

    return _SidebarShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceSwitcherHeader(),
          const _SidebarSectionHeader(
            icon: Icons.arrow_drop_down,
            label: 'Channels',
          ),
          for (final channel in channels) ChannelItem(channel: channel),
          SidebarActionButton(
            label: 'View all channels',
            onTap: () {
              ref
                  .read(menuProvider.notifier)
                  .select(MenuSection.channelsDirectory);
            },
          ),
          context.gapV(14),
          const _SidebarSectionHeader(icon: Icons.arrow_right, label: 'People'),
          const SidebarActionButton(label: 'View all people'),
        ],
      ),
    );
  }
}

class DmsSidebar extends StatelessWidget {
  const DmsSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return _SidebarShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceSwitcherHeader(),
          const SearchBox(label: 'Find a conversation'),
          Expanded(
            child: Center(
              child: Text(
                'No recent messages',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: colors.onPrimary.withValues(alpha: 0.62),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PeopleSidebar extends StatelessWidget {
  const PeopleSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return _SidebarShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceSwitcherHeader(),
          const SearchBox(label: 'Find a conversation'),
          Padding(
            padding: context.only(left: 16, right: 16, top: 24, bottom: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: context.s(14),
                  backgroundColor: colors.onPrimary,
                  child: Icon(
                    Icons.person,
                    size: context.s(16),
                    color: colors.sidebar,
                  ),
                ),
                context.gapH(12),
                Text(
                  'aimz',
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FilesSidebar extends StatelessWidget {
  const FilesSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return _SidebarShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceSwitcherHeader(),
          context.gapV(16),
          const FileSidebarItem(
            icon: Icons.file_copy_outlined,
            label: 'All files',
            isActive: true,
          ),
          const FileSidebarItem(
            icon: Icons.description_outlined,
            label: 'My files',
          ),
          const FileSidebarItem(
            icon: Icons.group_outlined,
            label: 'Shared with me',
          ),
          const FileSidebarItem(
            icon: Icons.delete_outline,
            label: 'Deleted files',
          ),
        ],
      ),
    );
  }
}

class ChannelItem extends StatelessWidget {
  const ChannelItem({required this.channel, super.key});

  final WorkspaceChannel channel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: context.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            channel.isPrivate ? Icons.lock_outline : Icons.tag,
            color: colors.onPrimary.withValues(alpha: 0.62),
            size: context.s(17),
          ),
          context.gapH(12),
          Expanded(
            child: Text(
              channel.name,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.onPrimary.withValues(alpha: 0.78),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarActionButton extends StatelessWidget {
  const SidebarActionButton({required this.label, this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: context.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.s(6)),
        child: Container(
          padding: context.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: colors.onPrimary.withValues(alpha: 0.04),
            border: Border.all(color: colors.onPrimary.withValues(alpha: 0.24)),
            borderRadius: BorderRadius.circular(context.s(6)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.72),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colors.onPrimary.withValues(alpha: 0.72),
                size: context.s(16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchBox extends StatelessWidget {
  const SearchBox({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: context.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Container(
        height: context.s(40),
        padding: context.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.onPrimary.withValues(alpha: 0.05),
          border: Border.all(color: colors.onPrimary.withValues(alpha: 0.28)),
          borderRadius: BorderRadius.circular(context.s(6)),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: colors.onPrimary, size: context.s(18)),
            context.gapH(8),
            Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.onPrimary.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FileSidebarItem extends StatelessWidget {
  const FileSidebarItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: context.s(64),
      margin: context.symmetric(horizontal: 18, vertical: 4),
      padding: context.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: isActive ? colors.primary.withValues(alpha: 0.10) : null,
        borderRadius: BorderRadius.circular(context.s(8)),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.onPrimary, size: context.s(26)),
          context.gapH(18),
          Text(
            label,
            style: context.textTheme.titleMedium?.copyWith(
              color: colors.onPrimary,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarShell extends StatelessWidget {
  const _SidebarShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.s(260),
      color: context.colors.sidebar,
      child: child,
    );
  }
}

class _SidebarSectionHeader extends StatelessWidget {
  const _SidebarSectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: context.only(left: 16, right: 16, top: 20, bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: colors.onPrimary, size: context.s(20)),
          context.gapH(8),
          Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
