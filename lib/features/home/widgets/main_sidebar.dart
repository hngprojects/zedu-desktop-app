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
    final colors = context.colors;
    final channels = ref.watch(channelProvider);

    return Container(
      width: 260,
      color: colors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceSwitcherHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Icon(Icons.arrow_drop_down, color: colors.onPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Channels',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
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
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.arrow_right, color: colors.onPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'People',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
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

    return Container(
      width: 260,
      color: colors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceSwitcherHeader(),
          const SearchBox(label: 'Find a conversation'),
          Expanded(
            child: Center(
              child: Text(
                'No recent messages',
                style: TextStyle(
                  color: colors.onPrimary.withValues(alpha: 0.62),
                  fontSize: 16,
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

    return Container(
      width: 260,
      color: colors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceSwitcherHeader(),
          const SearchBox(label: 'Find a conversation'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colors.onPrimary,
                  child: Icon(Icons.person, size: 16, color: colors.sidebar),
                ),
                const SizedBox(width: 12),
                Text(
                  'aimz',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 16,
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
    final colors = context.colors;

    return Container(
      width: 260,
      color: colors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceSwitcherHeader(),
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            channel.isPrivate ? Icons.lock_outline : Icons.tag,
            color: colors.onPrimary.withValues(alpha: 0.62),
            size: 17,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              channel.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onPrimary.withValues(alpha: 0.78),
                fontSize: 15,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(color: colors.onPrimary.withValues(alpha: 0.24)),
            borderRadius: BorderRadius.circular(6),
            color: colors.onPrimary.withValues(alpha: 0.04),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.72),
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colors.onPrimary.withValues(alpha: 0.72),
                size: 16,
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: colors.onPrimary.withValues(alpha: 0.28)),
          borderRadius: BorderRadius.circular(6),
          color: colors.onPrimary.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: colors.onPrimary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: colors.onPrimary.withValues(alpha: 0.78),
                fontSize: 15,
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
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      height: 64,
      decoration: BoxDecoration(
        color: isActive ? colors.primary.withValues(alpha: 0.10) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Icon(icon, color: colors.onPrimary, size: 26),
          const SizedBox(width: 18),
          Text(
            label,
            style: TextStyle(
              color: colors.onPrimary,
              fontSize: 18,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
