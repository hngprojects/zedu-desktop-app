import '../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('DmRepository', () {
    late MockApiBaseService mockApi;
    late DmRepository repository;

    setUp(() {
      mockApi = MockApiBaseService();
      repository = DmRepository(mockApi);
    });

    group('getMessages', () {
      test(
        'includes thread_id in queryParameters when threadId is provided',
        () async {
          when(
            () => mockApi.get<Map<String, dynamic>>(
              path: '/channels/channel-123/messages',
              queryParameters: {
                'page': 1,
                'limit': DmRepository.pageSize,
                'thread_id': 'thread-456',
              },
            ),
          ).thenAnswer(
            (_) async => ApiResponseModel<Map<String, dynamic>>(
              data: {
                'messages': [
                  {
                    'id': 'msg-1',
                    'content': 'Reply 1',
                    'channel_id': 'channel-123',
                    'thread_id': 'thread-456',
                  },
                ],
              },
              statusCode: 200,
            ),
          );

          final result = await repository.getMessages('channel-123', page: 1);

          expect(result, isNotEmpty);
          expect(result.first['id'], 'msg-1');
          expect(result.first['content'], 'Reply 1');

          verify(
            () => mockApi.get<Map<String, dynamic>>(
              path: '/channels/channel-123/messages',
              queryParameters: {
                'page': 1,
                'limit': DmRepository.pageSize,
                'thread_id': 'thread-456',
              },
            ),
          ).called(1);
        },
      );
    });

    group('sendMessage', () {
      test(
        'includes thread_id in post body data when threadId is provided',
        () async {
          when(
            () => mockApi.post<Map<String, dynamic>>(
              path: '/channels/channel-123/messages',
              data: {'content': 'Hello thread', 'thread_id': 'thread-456'},
            ),
          ).thenAnswer(
            (_) async => ApiResponseModel<Map<String, dynamic>>(
              data: {
                'data': {
                  'id': 'msg-new',
                  'content': 'Hello thread',
                  'channel_id': 'channel-123',
                  'threadId': 'thread-456',
                  'created_at': '2026-05-28T00:00:00Z',
                },
              },
              statusCode: 201,
            ),
          );

          final result = await repository.sendMessage(
            'channel-123',
            'Hello thread',
            threadId: 'thread-456',
          );

          expect(result, isNotEmpty);
          expect(result!['id'], 'msg-new');
          expect(result['threadId'], 'thread-456');

          verify(
            () => mockApi.post<Map<String, dynamic>>(
              path: '/channels/channel-123/messages',
              data: {'content': 'Hello thread', 'thread_id': 'thread-456'},
            ),
          ).called(1);
        },
      );
    });
  });
}
