import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('OrganizationRemoteDataSourceImpl', () {
    late MockApiBaseService mockApi;

    setUp(() {
      mockApi = MockApiBaseService();
    });

    test('calls POST /organisations with country name payload', () async {
      const request = CreateOrganizationRequest(
        name: 'Zedu',
        type: 'Education',
        country: 'Nigeria',
      );

      when(
        () => mockApi.post<Map<String, dynamic>>(
          path: '/organisations',
          data: {
            'name': 'Zedu',
            'type': 'Education',
            'country': 'Nigeria',
          },
        ),
      ).thenAnswer(
        (_) async => ApiResponseModel<Map<String, dynamic>>(
          data: {
            'data': {
              'id': 'org-1',
              'name': 'Zedu',
              'description': '',
              'email': '',
              'country': 'Nigeria',
              'industry': 'Education',
              'location': '',
              'owner_id': 'owner-1',
              'logo_url': '',
              'channels_count': 0,
              'total_messages_count': 0,
              'user_role': 'owner',
              'organisation_plan': {},
              'created_at': '2026-01-01T00:00:00.000Z',
              'updated_at': '2026-01-02T00:00:00.000Z',
            },
          },
          statusCode: 201,
        ),
      );

      final datasource = OrganizationRemoteDataSourceImpl(
        config: const AppConfig(
          apiBaseUrl: 'https://api.example.com',
          usesMockData: false,
        ),
        apiBaseService: mockApi,
      );

      await datasource.createOrganization(request);

      verify(
        () => mockApi.post<Map<String, dynamic>>(
          path: '/organisations',
          data: {
            'name': 'Zedu',
            'type': 'Education',
            'country': 'Nigeria',
          },
        ),
      ).called(1);
    });
  });
}
