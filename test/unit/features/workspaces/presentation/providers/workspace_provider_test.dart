import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

class FakeAuthNotifier extends AuthNotifier {
  final AuthState _initialState;
  FakeAuthNotifier(this._initialState);

  @override
  AuthState build() => _initialState;
}

void main() {
  group('WorkspaceNotifier Tests', () {
    late MockApiBaseService mockApiBaseService;
    late AuthState authState;

    setUp(() {
      mockApiBaseService = MockApiBaseService();
      
      // Register mockApiBaseService in locator
      if (locator.isRegistered<ApiBaseService>()) {
        locator.unregister<ApiBaseService>();
      }
      locator.registerSingleton<ApiBaseService>(mockApiBaseService);

      final json = Map<String, dynamic>.from(LoginResponseModel.mockLoginResponse);
      final userJson = Map<String, dynamic>.from(json['user'] as Map);
      userJson['id'] = 'user-123';
      json['user'] = userJson;
      final mockUser = LoginResponseModel.fromJson(json).user.toEntity();

      authState = AuthState(status: AuthStatus.authenticated, user: mockUser);
    });

    tearDown(() {
      if (locator.isRegistered<ApiBaseService>()) {
        locator.unregister<ApiBaseService>();
      }
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(() => FakeAuthNotifier(authState)),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('fetchWorkspaces filters workspaces created by other users', () async {
      final apiResponse = ApiResponseModel<Map<String, dynamic>>(
        statusCode: 200,
        data: {
          'data': [
            {
              'id': 'org-owner-123',
              'name': 'My Organization',
              'owner_id': 'user-123',
              'channels_count': 5,
            },
            {
              'id': 'org-creator-123',
              'name': 'My Created Org',
              'creator_id': 'user-123',
              'channels_count': 3,
            },
            {
              'id': 'org-other-user',
              'name': 'Other Org',
              'owner_id': 'user-999',
              'channels_count': 10,
            },
            {
              'id': 'org-no-owner',
              'name': 'No Owner Org',
              'channels_count': 1,
            }
          ]
        },
      );

      when(
        () => mockApiBaseService.get<Map<String, dynamic>>(
          path: '/users/organisations',
        ),
      ).thenAnswer((_) async => apiResponse);

      final container = createContainer();

      // Trigger workspace provider build and wait for fetchWorkspaces to finish
      container.read(workspaceProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(workspaceProvider);

      // Should filter out the organisation created by user-999 (Other Org)
      // but keep My Organization, My Created Org, and No Owner Org.
      final workspaceIds = state.workspaces.map((w) => w.id).toList();
      
      expect(workspaceIds, contains('org-owner-123'));
      expect(workspaceIds, contains('org-creator-123'));
      expect(workspaceIds, contains('org-no-owner'));
      expect(workspaceIds, isNot(contains('org-other-user')));
      
      expect(state.workspaces.length, equals(3));
    });
  });
}
