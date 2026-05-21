import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class SectionContent extends StatelessWidget {
  const SectionContent({required this.section, super.key});

  final MenuSection section;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case MenuSection.home:
        return const ChatArea();
      case MenuSection.dms:
        return const EmptyStatePanel(
          title: 'Recent Messages',
          icon: Icons.chat_bubble_outline,
        );
      case MenuSection.channelsDirectory:
        return const ChannelsDirectoryContent();
      case MenuSection.people:
        return const EmptyStatePanel(
          title: 'Recent Messages',
          icon: Icons.chat_bubble_outline,
        );
      case MenuSection.files:
        return const FilesContent();
      case MenuSection.buzz:
        return const BuzzContent();
    }
  }
}

class ChatArea extends StatelessWidget {
  const ChatArea({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStatePanel(
      title: 'Select a channel',
      icon: Icons.chat_bubble_outline,
    );
  }
}

class ChannelsDirectoryContent extends ConsumerStatefulWidget {
  const ChannelsDirectoryContent({super.key});

  @override
  ConsumerState<ChannelsDirectoryContent> createState() =>
      _ChannelsDirectoryContentState();
}

class _ChannelsDirectoryContentState
    extends ConsumerState<ChannelsDirectoryContent> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreateChannelModal() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const CreateChannelModal(),
    );

    if (result == null) return;

    final error = await ref
        .read(channelProvider.notifier)
        .createChannelRemote(
          name: result['name'] as String,
          visibility: result['type'] == 'Private'
              ? ChannelVisibility.private
              : ChannelVisibility.public,
          category: switch (result['category'] as String) {
            'Class' => ChannelCategory.classGroup,
            'Team' => ChannelCategory.team,
            _ => ChannelCategory.general,
          },
          organisationId: '019146f9-3d17-7294-93ac-9963ada4b7c1',
          username: 'aimz',
        );

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final channels = ref.watch(channelProvider);

    return Column(
      children: [
        Container(
          height: context.s(64),
          padding: context.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(bottom: BorderSide(color: colors.divider)),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Directories',
              style: textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Container(
          height: context.s(48),
          padding: context.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.divider)),
          ),
          child: Row(
            children: [
              Text(
                'People',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              context.gapH(28),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '# Channels',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  context.gapV(10),
                  Container(
                    width: context.s(72),
                    height: context.s(2),
                    color: colors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: context.only(left: 20, right: 20, top: 18, bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _searchController,
                  hint: 'Find a channel',
                  icon: Icons.search,
                ),
              ),
              context.gapH(10),
              AppButton.outlined(
                label: 'New Channel',
                expand: false,
                height: context.s(57),
                leading: Icon(Icons.add, size: context.s(18)),
                onPressed: _openCreateChannelModal,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: context.symmetric(horizontal: 20),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];

              return Container(
                margin: context.only(bottom: 10),
                padding: context.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.divider),
                  borderRadius: BorderRadius.circular(context.s(8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${channel.isPrivate ? 'Private ' : '# '}${channel.name}',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    context.gapV(8),
                    Text(
                      'Joined ${channel.membersCount} members',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.success,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class FilesContent extends StatefulWidget {
  const FilesContent({super.key});

  @override
  State<FilesContent> createState() => _FilesContentState();
}

class _FilesContentState extends State<FilesContent> {
  bool showFiles = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Column(
      children: [
        Container(
          height: context.s(88),
          padding: context.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(bottom: BorderSide(color: colors.divider)),
          ),
          child: Row(
            children: [
              Text(
                'All files',
                style: textTheme.titleLarge?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _OutlineActionButton(
                icon: Icons.upload_outlined,
                label: 'Upload File',
              ),
              context.gapH(12),
              _OutlineActionButton(
                icon: Icons.create_new_folder_outlined,
                label: 'New Folder',
              ),
            ],
          ),
        ),
        Container(
          height: context.s(88),
          padding: context.only(left: 56),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(bottom: BorderSide(color: colors.divider)),
          ),
          child: Row(
            children: [
              _FilesTab(
                label: 'Folders',
                isActive: !showFiles,
                onTap: () => setState(() => showFiles = false),
              ),
              context.gapH(36),
              _FilesTab(
                label: 'Files',
                isActive: showFiles,
                onTap: () => setState(() => showFiles = true),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: _FileEmptyState(
              title: showFiles ? 'No files yet' : 'No folders yet',
              subtitle: showFiles
                  ? 'Upload or drag & drop to get started'
                  : 'Create a folder to get started',
              showUploadButton: showFiles,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilesTab extends StatelessWidget {
  const _FilesTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: context.s(88),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              label,
              style: context.textTheme.bodyLarge?.copyWith(
                color: isActive ? colors.primary : colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            context.gapV(14),
            Container(
              width: context.s(88),
              height: context.s(3),
              color: isActive ? colors.primary : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _FileEmptyState extends StatelessWidget {
  const _FileEmptyState({
    required this.title,
    required this.subtitle,
    required this.showUploadButton,
  });

  final String title;
  final String subtitle;
  final bool showUploadButton;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Transform.translate(
      offset: Offset(0, context.s(-20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_copy_outlined,
            size: context.s(110),
            color: colors.primary.withValues(alpha: 0.45),
          ),
          context.gapV(24),
          Text(
            title,
            style: textTheme.headlineSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          context.gapV(14),
          Text(
            subtitle,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (showUploadButton) ...[
            context.gapV(26),
            AppButton(
              label: 'Upload File',
              expand: false,
              height: context.s(48),
              leading: const Icon(Icons.upload_outlined),
              onPressed: () {},
            ),
            context.gapV(16),
            Text(
              'or drag & drop files here',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BuzzContent extends StatelessWidget {
  const BuzzContent({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return SingleChildScrollView(
      child: Padding(
        padding: context.only(top: 120),
        child: Column(
          children: [
            Text(
              'Seamless video calls and meetings for every\nlearning community.',
              textAlign: TextAlign.center,
              style: textTheme.headlineLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
            context.gapV(20),
            Text(
              'Connect classrooms, cohorts, and teams in one shared space',
              style: textTheme.bodyLarge?.copyWith(color: colors.textHint),
            ),
            context.gapV(56),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  label: 'New meeting',
                  expand: false,
                  height: context.s(48),
                  leading: const Icon(Icons.calendar_month_outlined),
                  onPressed: () {},
                ),
                context.gapH(24),
                Container(
                  width: context.s(280),
                  height: context.s(48),
                  padding: context.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.divider),
                    borderRadius: BorderRadius.circular(context.s(6)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.keyboard_outlined, color: colors.textHint),
                      context.gapH(12),
                      Expanded(
                        child: Text(
                          'Enter a code or link',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colors.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                context.gapH(24),
                Text(
                  'Join',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.textHint,
                    fontWeight: FontWeight.w700,
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

class EmptyStatePanel extends StatelessWidget {
  const EmptyStatePanel({required this.title, required this.icon, super.key});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.s(64), color: colors.primary),
          context.gapV(20),
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppButton.outlined(
      label: label,
      expand: false,
      height: context.s(48),
      leading: Icon(icon, size: context.s(18)),
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: context.symmetric(horizontal: 18),
      ),
    );
  }
}