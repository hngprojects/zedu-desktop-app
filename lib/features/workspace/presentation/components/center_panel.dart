import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class CenterPanel extends ConsumerWidget {
  const CenterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.watch(workspaceProvider);
    final selectedItem = workspaceState.selectedItem;

    if (workspaceState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (workspaceState.errorMessage != null) {
      return _CenterPanelErrorState(
        message: workspaceState.errorMessage!,
        onRetry: () {
          ref.read(workspaceProvider.notifier).retrySelectedItem();
        },
      );
    }

    if (selectedItem == null) {
      return _CenterPanelErrorState(
        message: 'This conversation is no longer available.',
        onRetry: () {
          ref.read(workspaceProvider.notifier).retrySelectedItem();
        },
      );
    }

    return Column(
      children: [
        _CenterPanelHeader(selectedItem: selectedItem),
        Expanded(child: _ConversationEmptyState(selectedItem: selectedItem)),
        _MessageComposer(selectedItem: selectedItem),
      ],
    );
  }
}

class _CenterPanelHeader extends StatelessWidget {
  const _CenterPanelHeader({required this.selectedItem});

  final WorkspaceItem selectedItem;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final titlePrefix = selectedItem.type == WorkspaceItemType.channel
        ? '# '
        : '';

    return Container(
      height: context.s(73),
      padding: context.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          Text(
            '$titlePrefix${selectedItem.name}',
            style: context.textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.headphones_rounded, size: context.s(18)),
            label: const Text('Start Buzz'),
            style: OutlinedButton.styleFrom(
              padding: context.symmetric(horizontal: 12, vertical: 10),
              side: BorderSide(color: colors.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.s(6)),
              ),
              foregroundColor: colors.textPrimary,
            ),
          ),
          context.gapH(14),
          Container(
            width: context.s(1),
            height: context.s(28),
            color: colors.divider,
          ),
          context.gapH(14),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.person, size: context.s(20)),
            style: IconButton.styleFrom(
              backgroundColor: colors.primary.withValues(alpha: 0.08),
              foregroundColor: colors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.s(6)),
                side: BorderSide(color: colors.divider),
              ),
            ),
          ),
          context.gapH(8),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert_rounded, size: context.s(20)),
            style: IconButton.styleFrom(
              foregroundColor: colors.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.s(6)),
                side: BorderSide(color: colors.divider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationEmptyState extends StatelessWidget {
  const _ConversationEmptyState({required this.selectedItem});

  final WorkspaceItem selectedItem;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final titlePrefix = selectedItem.type == WorkspaceItemType.channel
        ? '# '
        : '';

    return Container(
      width: double.infinity,
      color: colors.background,
      child: Padding(
        padding: context.only(left: 20, top: 150, right: 20),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.s(650)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: context.s(24),
                      backgroundColor: colors.primary.withValues(alpha: 0.08),
                      child: SvgPicture.asset(
                        'assets/svgs/welcome.svg',
                        width: context.s(44),
                        height: context.s(44),
                      ),
                    ),
                    context.gapH(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to $titlePrefix${selectedItem.name}',
                            style: context.textTheme.headlineSmall?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          context.gapV(4),
                          Text(
                            'Share all information relating to general here. All team members await you! 😊',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                context.gapV(12),
                Padding(
                  padding: context.only(left: 56),
                  child: const _InviteTeammatesCard(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteTeammatesCard extends StatelessWidget {
  const _InviteTeammatesCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: context.s(340),
      padding: context.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.divider),
        borderRadius: BorderRadius.circular(context.s(6)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: context.s(16),
            backgroundColor: colors.primary.withValues(alpha: 0.08),
            child: Icon(
              Icons.group_add_outlined,
              size: context.s(16),
              color: colors.primary,
            ),
          ),
          context.gapH(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invite teammates',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              context.gapV(4),
              Text(
                'Add your entire team in seconds',
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({required this.selectedItem});

  final WorkspaceItem selectedItem;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: context.only(left: 20, right: 20, bottom: 16),
      color: colors.background,
      child: Container(
        height: context.s(144),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(color: colors.borderOutline),
          borderRadius: BorderRadius.circular(context.s(12)),
        ),
        child: Column(
          children: [
            SizedBox(
              height: context.s(40),
              child: Row(
                children: [
                  context.gapH(16),
                  _ComposerIcon(icon: Icons.format_bold),
                  _ComposerIcon(icon: Icons.format_italic),
                  _ComposerIcon(icon: Icons.strikethrough_s),
                  VerticalDivider(width: context.s(18), color: colors.divider),
                  _ComposerIcon(icon: Icons.link),
                  _ComposerIcon(icon: Icons.format_list_numbered),
                  _ComposerIcon(icon: Icons.format_list_bulleted),
                  VerticalDivider(width: context.s(18), color: colors.divider),
                  _ComposerIcon(icon: Icons.code),
                ],
              ),
            ),
            Divider(height: 1, color: colors.divider),
            Expanded(
              child: TextField(
                minLines: 1,
                maxLines: null,
                cursorColor: colors.primary,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'Message ${selectedItem.name}',
                  hintStyle: context.textTheme.bodySmall?.copyWith(
                    color: colors.textHint.withValues(alpha: 0.65),
                  ),
                  contentPadding: context.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: context.s(36),
              child: Row(
                children: [
                  context.gapH(14),
                  _ComposerCircleIcon(icon: Icons.add),
                  context.gapH(8),
                  Text(
                    'Aa',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  context.gapH(10),
                  _ComposerIcon(icon: Icons.emoji_emotions_outlined),
                  _ComposerIcon(icon: Icons.alternate_email),
                  context.gapH(12),
                  VerticalDivider(width: context.s(18), color: colors.divider),
                  _ComposerIcon(icon: Icons.videocam_outlined),
                  _ComposerIcon(icon: Icons.mic_none_outlined),
                  context.gapH(12),
                  VerticalDivider(width: context.s(18), color: colors.divider),
                  _ComposerIcon(icon: Icons.crop_square),
                  const Spacer(),
                  Icon(
                    Icons.send_outlined,
                    size: context.s(22),
                    color: colors.textHint,
                  ),
                  context.gapH(16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerIcon extends StatelessWidget {
  const _ComposerIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: context.symmetric(horizontal: 4),
      child: Icon(icon, size: context.s(16), color: colors.textHint),
    );
  }
}

class _ComposerCircleIcon extends StatelessWidget {
  const _ComposerCircleIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: context.s(24),
      height: context.s(24),
      decoration: BoxDecoration(
        color: colors.divider.withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: context.s(16), color: colors.textSecondary),
    );
  }
}

class _CenterPanelErrorState extends StatelessWidget {
  const _CenterPanelErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.s(420)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: context.s(40),
              color: colors.error,
            ),
            context.gapV(12),
            Text(
              'Unable to load conversation',
              style: context.textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            context.gapV(8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textHint,
              ),
            ),
            context.gapV(20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, size: context.s(18)),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
