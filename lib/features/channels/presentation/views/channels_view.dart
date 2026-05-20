import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ChannelsView extends ConsumerStatefulWidget {
  const ChannelsView({super.key, this.initialChannelId});

  final String? initialChannelId;

  @override
  ConsumerState<ChannelsView> createState() => _ChannelsViewState();
}

class _ChannelsViewState extends ConsumerState<ChannelsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final channelId =
          widget.initialChannelId?.trim().isNotEmpty == true
          ? widget.initialChannelId!.trim()
          : ChannelsDevDefaults.mockChannelId;
      ref.read(channelsNotifierProvider.notifier).openChannel(channelId);
    });
  }

  @override
  void didUpdateWidget(covariant ChannelsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialChannelId != oldWidget.initialChannelId &&
        widget.initialChannelId != null &&
        widget.initialChannelId!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(channelsNotifierProvider.notifier)
            .openChannel(widget.initialChannelId!.trim());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChannelsState>(channelsNotifierProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          AppToastService.show(
            context,
            type: AppToastType.error,
            message: next.error!,
          );
        });
      }
    });

    final state = ref.watch(channelsNotifierProvider);
    final notifier = ref.read(channelsNotifierProvider.notifier);
    final colors = context.colors;
    final authState = ref.watch(authNotifierProvider);
    final currentUserName = authState.user?.fullname.toLowerCase().trim() ?? '';

    return Column(
      children: [
        _ChannelsHeader(
          channelName: state.messages.isNotEmpty
              ? state.messages.first.channelName
              : 'general',
          isRefreshing: state.isRefreshing || state.isPolling,
          onRefresh: notifier.refreshCurrentChannel,
        ),
        Expanded(
          child: _buildBody(
            context,
            state,
            currentUserName,
            onReload: notifier.refreshCurrentChannel,
          ),
        ),
        if (!state.hasSelectedChannel)
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Text('Select a channel to start messaging.'),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.divider)),
            ),
            child: ChannelMessageComposer(
              enabled: state.hasSelectedChannel,
              isSending: state.isSending,
              placeholder:
                  'Message #${state.messages.isNotEmpty ? state.messages.first.channelName : 'general'}',
              onSend: (contentHtml) {
                notifier.sendMessage(contentHtml: contentHtml);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    ChannelsState state,
    String currentUserName, {
    required Future<void> Function() onReload,
  }) {
    if (!state.hasSelectedChannel) {
      return const ChannelsEmptyState(
        title: 'Select a channel',
        subtitle:
            'A channel is required before fetching messages. Channel creation will be wired after branch merge.',
      );
    }

    if (state.isLoading && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.messages.isEmpty) {
      return ChannelsEmptyState(
        title: 'No messages yet',
        subtitle: 'Start the conversation in this channel.',
      );
    }

    return RefreshIndicator(
      onRefresh: onReload,
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.only(top: 12, bottom: 16),
        itemCount: state.messages.length,
        itemBuilder: (context, index) {
          final message = state.messages[index];
          final authorName = message.fullName.toLowerCase().trim();
          final isMine = currentUserName.isNotEmpty && authorName == currentUserName;
          return ChannelMessageTile(message: message, isMine: isMine);
        },
      ),
    );
  }
}

class _ChannelsHeader extends StatelessWidget {
  const _ChannelsHeader({
    required this.channelName,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final String channelName;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          Text(
            '# $channelName',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onRefresh,
            tooltip: 'Refresh',
            icon: isRefreshing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  )
                : Icon(Icons.refresh, color: colors.textHint),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: colors.divider),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.headphones_outlined, size: 18, color: colors.textPrimary),
                const SizedBox(width: 8),
                Text(
                  'Start Buzz',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 14,
            backgroundColor: colors.accent,
            child: Icon(Icons.person, size: 18, color: colors.onPrimary),
          ),
          const SizedBox(width: 8),
          Icon(Icons.more_vert, color: colors.textHint),
        ],
      ),
    );
  }
}
