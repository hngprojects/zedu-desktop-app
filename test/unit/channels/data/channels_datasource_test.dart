import '../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('ChannelsRemoteDataSourceImpl', () {
    late MockApiBaseService mockApi;

    setUp(() {
      mockApi = MockApiBaseService();
    });

    test('returns mock response when usesMockData is true', () async {
      final datasource = ChannelsRemoteDataSourceImpl(
        config: const AppConfig(apiBaseUrl: 'https://api.example.com', usesMockData: true),
        apiBaseService: mockApi,
      );

      final result = await datasource.fetchChannelMessages(
        channelId: ChannelsDevDefaults.mockChannelId,
      );

      expect(result.messages, isNotEmpty);
      verifyNever(
        () => mockApi.get<Map<String, dynamic>>(
          path: any(named: 'path'),
          queryParameters: any(named: 'queryParameters'),
        ),
      );
    });

    test('calls GET fetch endpoint with path and pagination', () async {
      when(
        () => mockApi.get<Map<String, dynamic>>(
          path: 'threads/channels/${ChannelsDevDefaults.mockChannelId}',
          queryParameters: {'page': 1, 'limit': 10},
        ),
      ).thenAnswer(
        (_) async => ApiResponseModel<Map<String, dynamic>>(
          data: {
            'status': 'success',
            'status_code': 200,
            'message': 'Data retrieved successfully',
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
          },
          statusCode: 200,
        ),
      );

      final datasource = ChannelsRemoteDataSourceImpl(
        config: const AppConfig(apiBaseUrl: 'https://api.example.com', usesMockData: false),
        apiBaseService: mockApi,
      );

      final result = await datasource.fetchChannelMessages(
        channelId: ChannelsDevDefaults.mockChannelId,
        page: 1,
        limit: 10,
      );

      expect(result.messages.length, 1);
      verify(
        () => mockApi.get<Map<String, dynamic>>(
          path: 'threads/channels/${ChannelsDevDefaults.mockChannelId}',
          queryParameters: {'page': 1, 'limit': 10},
        ),
      ).called(1);
    });

    test('calls POST send endpoint with html content', () async {
      when(
        () => mockApi.post<Map<String, dynamic>>(
          path: 'threads/${ChannelsDevDefaults.mockChannelId}',
          data: {
            'content': '<p><strong>Hello</strong></p>',
          },
        ),
      ).thenAnswer(
        (_) async => ApiResponseModel<Map<String, dynamic>>(
          data: {
            'status': 'success',
            'status_code': 201,
            'message': 'Thread message added successfully',
            'data': {
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
              'message': '<p><strong>Hello</strong></p>',
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
          },
          statusCode: 201,
        ),
      );

      final datasource = ChannelsRemoteDataSourceImpl(
        config: const AppConfig(apiBaseUrl: 'https://api.example.com', usesMockData: false),
        apiBaseService: mockApi,
      );

      final result = await datasource.sendChannelMessage(
        channelId: ChannelsDevDefaults.mockChannelId,
        contentHtml: '<p><strong>Hello</strong></p>',
      );

      expect(result.message, '<p><strong>Hello</strong></p>');
      verify(
        () => mockApi.post<Map<String, dynamic>>(
          path: 'threads/${ChannelsDevDefaults.mockChannelId}',
          data: {
            'content': '<p><strong>Hello</strong></p>',
          },
        ),
      ).called(1);
    });
  });
}
