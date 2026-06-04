import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('UserProfileRemoteDataSourceImpl', () {
    late MockApiBaseService mockApi;

    setUp(() {
      mockApi = MockApiBaseService();
    });

    group('inviteMember', () {
      test('returns mock response when usesMockData is true', () async {
        final datasource = UserProfileRemoteDataSourceImpl(
          config: const AppConfig(
      googleClientId: 'test-client-id',
            apiBaseUrl: 'https://api.example.com',
            usesMockData: true,
          ),
          apiBaseService: mockApi,
        );

        final result = await datasource.inviteMember(
          email: 'test@example.com',
          role: '01910544-d1e1-7ada-bdac-c761e527ec92',
          orgId: 'org-123',
          userId: 'user-456',
        );

        expect(result.id, 'user-456');
        expect(result.email, 'test@example.com');
        expect(result.role, '01910544-d1e1-7ada-bdac-c761e527ec92');
        expect(result.status, TeamMemberStatus.active);

        verifyNever(
          () => mockApi.post<Map<String, dynamic>>(
            path: any(named: 'path'),
            data: any(named: 'data'),
          ),
        );
      });

      test(
        'calls POST /organisations/org-123/users with user_id and role_Id when userId is present',
        () async {
          when(
            () => mockApi.post<Map<String, dynamic>>(
              path: '/organisations/org-123/users',
              data: {
                'user_id': 'user-456',
                'role_Id': '01910544-d1e1-7ada-bdac-c761e527ec92',
              },
            ),
          ).thenAnswer(
            (_) async => ApiResponseModel<Map<String, dynamic>>(
              data: {
                'status': 'success',
                'status_code': 200,
                'message': 'User added successfully',
              },
              statusCode: 200,
            ),
          );

          final datasource = UserProfileRemoteDataSourceImpl(
            config: const AppConfig(
      googleClientId: 'test-client-id',
              apiBaseUrl: 'https://api.example.com',
              usesMockData: false,
            ),
            apiBaseService: mockApi,
          );

          final result = await datasource.inviteMember(
            email: 'test@example.com',
            role: '01910544-d1e1-7ada-bdac-c761e527ec92',
            orgId: 'org-123',
            userId: 'user-456',
          );

          expect(result.id, 'user-456');
          expect(result.email, 'test@example.com');
          expect(result.status, TeamMemberStatus.active);

          verify(
            () => mockApi.post<Map<String, dynamic>>(
              path: '/organisations/org-123/users',
              data: {
                'user_id': 'user-456',
                'role_Id': '01910544-d1e1-7ada-bdac-c761e527ec92',
              },
            ),
          ).called(1);
        },
      );

      test('calls POST /invite when userId is null/empty', () async {
        when(
          () => mockApi.post<Map<String, dynamic>>(
            path: '/invite',
            data: {
              'org_id': 'org-123',
              'emails': ['test@example.com'],
              'role_id': '01910544-d1e1-7ada-bdac-c761e527ec92',
            },
          ),
        ).thenAnswer(
          (_) async => ApiResponseModel<Map<String, dynamic>>(
            data: {
              'data': {
                'invitations': [
                  {
                    'id': 'member-new',
                    'email': 'test@example.com',
                    'sent_at': 'Pending',
                  },
                ],
              },
            },
            statusCode: 200,
          ),
        );

        final datasource = UserProfileRemoteDataSourceImpl(
          config: const AppConfig(
      googleClientId: 'test-client-id',
            apiBaseUrl: 'https://api.example.com',
            usesMockData: false,
          ),
          apiBaseService: mockApi,
        );

        final result = await datasource.inviteMember(
          email: 'test@example.com',
          role: '01910544-d1e1-7ada-bdac-c761e527ec92',
          orgId: 'org-123',
        );

        expect(result.id, 'member-new');
        expect(result.email, 'test@example.com');
        expect(result.status, TeamMemberStatus.pending);

        verify(
          () => mockApi.post<Map<String, dynamic>>(
            path: '/invite',
            data: {
              'org_id': 'org-123',
              'emails': ['test@example.com'],
              'role_id': '01910544-d1e1-7ada-bdac-c761e527ec92',
            },
          ),
        ).called(1);
      });
    });
  });
}
