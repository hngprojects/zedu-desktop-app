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

class ChannelsDirectoryContent extends ConsumerWidget {
  const ChannelsDirectoryContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final channels = ref.watch(channelProvider);

    return Column(
      children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(bottom: BorderSide(color: colors.divider)),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Directories',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.divider)),
          ),
          child: Row(
            children: [
              Text(
                'People',
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(width: 28),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '# Channels',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(width: 72, height: 2, color: colors.primary),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.divider),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 16, color: colors.textHint),
                      const SizedBox(width: 8),
                      Text(
                        'Find a channel',
                        style: TextStyle(color: colors.textHint, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
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

                  if (error != null && context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error)));
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('New Channel'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.divider),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(index == 0 ? 8 : 0),
                    bottom: Radius.circular(
                      index == channels.length - 1 ? 8 : 0,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${channel.isPrivate ? 'Private ' : '# '}${channel.name}',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Joined   ${channel.membersCount} members',
                      style: TextStyle(color: colors.success, fontSize: 12),
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

    return Column(
      children: [
        Container(
          height: 88,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(bottom: BorderSide(color: colors.divider)),
          ),
          child: Row(
            children: [
              Text(
                'All files',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _OutlineActionButton(
                icon: Icons.upload_outlined,
                label: 'Upload File',
              ),
              const SizedBox(width: 12),
              _OutlineActionButton(
                icon: Icons.create_new_folder_outlined,
                label: 'New Folder',
              ),
            ],
          ),
        ),
        Container(
          height: 88,
          padding: const EdgeInsets.only(left: 56),
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
              const SizedBox(width: 36),
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
        height: 88,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? colors.primary : colors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 88,
              height: 3,
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

    return Transform.translate(
      offset: const Offset(0, -20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_copy_outlined,
            size: 110,
            color: colors.primary.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: TextStyle(color: colors.textSecondary, fontSize: 16),
          ),
          if (showUploadButton) ...[
            const SizedBox(height: 26),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.upload_outlined),
              label: const Text('Upload File'),
            ),
            const SizedBox(height: 16),
            Text(
              'or drag & drop files here',
              style: TextStyle(color: colors.textSecondary, fontSize: 15),
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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Column(
          children: [
            Text(
              'Seamless video calls and meetings for every\nlearning community.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Connect classrooms, cohorts, and teams in one shared space',
              style: TextStyle(color: colors.textHint, fontSize: 17),
            ),
            const SizedBox(height: 56),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('New meeting'),
                ),
                const SizedBox(width: 24),
                Container(
                  width: 280,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.divider),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.keyboard_outlined, color: colors.textHint),
                      const SizedBox(width: 12),
                      Text(
                        'Enter a code or link',
                        style: TextStyle(color: colors.textHint, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Text(
                  'Join',
                  style: TextStyle(
                    color: colors.textHint,
                    fontSize: 16,
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

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: colors.primary),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
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
    final colors = context.colors;

    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.primary,
        side: BorderSide(color: colors.borderOutline),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}
