import '../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockChannelsRemoteDataSource extends Mock implements ChannelsRemoteDataSource {}

void main() {
  group('ChannelsRepositoryImpl', () {
    late MockChannelsRemoteDataSource remote;
    late ChannelsRepositoryImpl repository;

    setUp(() {
      remote = MockChannelsRemoteDataSource();
      repository = ChannelsRepositoryImpl(remote: remote);
    });

    test('returns Success on fetch messages', () async {
      when(
        () => remote.fetchChannelMessages(
          channelId: any(named: 'channelId'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => PaginatedChannelMessagesModel.fromJson({
          'data': [
            {
              'thread_id': 'thread-1',
              'channels_id': ChannelsDevDefaults.mockChannelId,
              'org_id': ChannelsDevDefaults.mockOrgId,
              'username': 'alameen',
              'status': 'success',
              'created_at': '2026-05-20T15:28:50.715175123Z',
              'updated_at': '2026-05-20T15:28:50.715175123Z',
              'message_count': 0,
              'last_reply': '0001-01-01T00:00:00Z',
              'avatar_url': '',
              'default_avatar_url': '',
              'user_type': 'user',
              'type': 'message',
              'message': '<p>hello</p>',
              'channel_name': 'general',
              'channel_type': 'public',
              'current_status': 'pending',
              'full_name': 'alameen',
              'email': 'a@b.com',
              'user_id': 'user-1',
              'edited': false,
              'is_pinned': false,
              'pinned_details': <String, dynamic>{},
              'reactions': null,
            },
          ],
          'pagination': {
            'current_page': 1,
            'page_count': 1,
            'total_pages_count': 1,
          },
        }),
      );

      final result = await repository.fetchChannelMessages(
        channelId: ChannelsDevDefaults.mockChannelId,
      );

      expect(result, isA<Success<PaginatedChannelMessages>>());
    });

    test('returns Failure on datasource ApiFailure', () async {
      when(
        () => remote.fetchChannelMessages(
          channelId: any(named: 'channelId'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(const ApiFailure(message: 'Nope', kind: ApiFailureKind.client));

      final result = await repository.fetchChannelMessages(
        channelId: ChannelsDevDefaults.mockChannelId,
      );

      expect(result, isA<Failure<PaginatedChannelMessages>>());
    });

    test('returns Success on send message', () async {
      when(
        () => remote.sendChannelMessage(
          channelId: any(named: 'channelId'),
          contentHtml: any(named: 'contentHtml'),
          threadId: null,
          media: const <ChannelMedia>[],
          mentions: const <ChannelMention>[],
        ),
      ).thenAnswer(
        (_) async => ChannelMessageModel.fromJson({
          'thread_id': 'thread-1',
          'channels_id': ChannelsDevDefaults.mockChannelId,
          'org_id': ChannelsDevDefaults.mockOrgId,
          'username': 'alameen',
          'status': 'success',
          'created_at': '2026-05-20T15:28:50.715175123Z',
          'updated_at': '2026-05-20T15:28:50.715175123Z',
          'message_count': 0,
          'last_reply': '0001-01-01T00:00:00Z',
          'avatar_url': '',
          'default_avatar_url': '',
          'user_type': 'user',
          'type': 'message',
          'message': '<p>hello</p>',
          'channel_name': 'general',
          'channel_type': 'public',
          'current_status': 'pending',
          'full_name': 'alameen',
          'email': 'a@b.com',
          'user_id': 'user-1',
          'edited': false,
          'is_pinned': false,
          'pinned_details': <String, dynamic>{},
          'reactions': null,
        }),
      );

      final result = await repository.sendChannelMessage(
        channelId: ChannelsDevDefaults.mockChannelId,
        contentHtml: '<p>hello</p>',
      );

      expect(result, isA<Success<ChannelMessage>>());
    });
  });
}
