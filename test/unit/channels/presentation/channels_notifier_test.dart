import '../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class FakeChannelsRepository implements ChannelsRepository {
  FakeChannelsRepository(this.messagesByChannel);

  final Map<String, List<ChannelMessage>> messagesByChannel;

  @override
  Future<Result<PaginatedChannelMessages>> fetchChannelMessages({
    required String channelId,
    int page = 1,
    int limit = 20,
  }) async {
    final messages = messagesByChannel[channelId] ?? const [];
    final offset = (page - 1) * limit;
    final pageItems = offset >= messages.length
        ? const <ChannelMessage>[]
        : messages.skip(offset).take(limit).toList();

    return Success(
      PaginatedChannelMessages(
        messages: pageItems,
        pagination: ChannelPagination(
          currentPage: page,
          pageCount: pageItems.length,
          totalPagesCount: messages.isEmpty ? 1 : (messages.length / limit).ceil(),
        ),
      ),
    );
  }

  @override
  Future<Result<ChannelMessage>> sendChannelMessage({
    required String channelId,
    required String contentHtml,
    String? threadId,
    List<ChannelMedia> media = const [],
    List<ChannelMention> mentions = const [],
  }) async {
    final message = ChannelMessage(
      threadId: threadId ?? 'thread-${DateTime.now().millisecondsSinceEpoch}',
      channelId: channelId,
      orgId: ChannelsDevDefaults.mockOrgId,
      username: 'alameen',
      status: 'success',
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      messageCount: 0,
      lastReply: null,
      avatarUrl: '',
      defaultAvatarUrl: '',
      userType: 'user',
      type: 'message',
      messageHtml: contentHtml,
      channelName: 'general',
      channelType: 'public',
      currentStatus: 'pending',
      fullName: 'alameen',
      email: 'alameensad6@gmail.com',
      userId: 'user-1',
      edited: false,
      isPinned: false,
      pinnedDetails: const <String, dynamic>{},
      reactions: null,
    );

    final existing = messagesByChannel[channelId] ?? <ChannelMessage>[];
    messagesByChannel[channelId] = [message, ...existing];
    return Success(message);
  }
}

void main() {
  group('ChannelsNotifier', () {
    test('openChannel requires non-empty channel id', () async {
      final repository = FakeChannelsRepository(<String, List<ChannelMessage>>{});
      final container = ProviderContainer(
        overrides: [
          channelsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(channelsNotifierProvider.notifier);
      await notifier.openChannel('  ');

      final state = container.read(channelsNotifierProvider);
      expect(state.hasSelectedChannel, false);
      expect(state.error, 'Select a channel');
    });

    test('openChannel loads data and sendMessage appends new message', () async {
      final initial = ChannelMessage(
        threadId: 'thread-1',
        channelId: ChannelsDevDefaults.mockChannelId,
        orgId: ChannelsDevDefaults.mockOrgId,
        username: 'jane',
        status: 'success',
        createdAt: DateTime.utc(2026, 5, 20, 10),
        updatedAt: DateTime.utc(2026, 5, 20, 10),
        messageCount: 0,
        lastReply: null,
        avatarUrl: '',
        defaultAvatarUrl: '',
        userType: 'user',
        type: 'message',
        messageHtml: '<p>hello</p>',
        channelName: 'general',
        channelType: 'public',
        currentStatus: 'pending',
        fullName: 'Jane',
        email: 'jane@example.com',
        userId: 'user-jane',
        edited: false,
        isPinned: false,
        pinnedDetails: const <String, dynamic>{},
        reactions: null,
      );

      final repository = FakeChannelsRepository({
        ChannelsDevDefaults.mockChannelId: [initial],
      });

      final container = ProviderContainer(
        overrides: [
          channelsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(channelsNotifierProvider.notifier);
      await notifier.openChannel(ChannelsDevDefaults.mockChannelId);
      await notifier.sendMessage(contentHtml: '<p><strong>new</strong></p>');

      final state = container.read(channelsNotifierProvider);
      expect(state.messages, isNotEmpty);
      expect(state.messages.first.messageHtml, '<p><strong>new</strong></p>');
    });
  });
}
